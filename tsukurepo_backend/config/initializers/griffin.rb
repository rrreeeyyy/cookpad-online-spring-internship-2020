# frozen_string_literal: true

require 'grpc/health/checker'

require 'griffin/interceptors/server/clear_connection_interceptor'
require 'griffin/interceptors/server/filtered_payload_interceptor'
require 'griffin/interceptors/server/logging_interceptor'
require 'griffin/interceptors/server/x_request_id_interceptor'
require 'griffin/interceptors/server/timeout_interceptor'

app_id = ENV['APPLICATION_ID'] || 'tsukurepo-grpc'
port = ENV['PORT'] || 8081

health_check_service = Grpc::Health::Checker.new
health_check_service.add_status(app_id, Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING)

if Rails.env.development? && ARGV[0]&.include?('Griffin::Server')
  Rails.application.runner do
    # Send logs to stdout like `rails s`
    # https://guides.rubyonrails.org/initialization.html#rails-server-start
    console = ActiveSupport::Logger.new($stdout)
    console.formatter = Rails.logger.formatter
    console.level = Rails.logger.level
    Rails.logger.extend(ActiveSupport::Logger.broadcast(console))
  end
end

pool_min, pool_max = *(ENV['GRIFFIN_THREAD_SIZE'] || '10,10').split(',', 2).map(&:to_i)
connection_min, connection_max = *(ENV['GRIFFIN_CONNECTION_SIZE'] || '1,3').split(',', 2).map(&:to_i)
worker_size = (ENV['GRIFFIN_WORKER_SIZE'] || 2).to_i

if worker_size < 2
  Rails.logger.warn("Unexpected worker size (via GRIFFIN_WORKER_SIZE): #{worker_size}. If you want to enable graceful reloading, set GRIFFIN_WORKER_SIZE greater than 1.")
end

interceptors = [
  Rails.env.development? ? nil : Griffin::Interceptors::Server::TimeoutInterceptor.new(30),
  Griffin::Interceptors::Server::FilteredPayloadInterceptor.new(filter_parameters: Rails.configuration.filter_parameters),
  Griffin::Interceptors::Server::LoggingInterceptor.new,
  Griffin::Interceptors::Server::ClearConnectionInterceptor.new,
  Griffin::Interceptors::Server::XRequestIdInterceptor.new,
].compact

if Rails.env.production? && worker_size >= 2 && ENV['MEMORY_LIMIT_MIN'] && ENV['MEMORY_LIMIT_MAX']
  memory_limit_min = ENV.fetch('MEMORY_LIMIT_MIN').to_i
  memory_limit_max = ENV.fetch('MEMORY_LIMIT_MAX').to_i
  interceptors << Griffin::Interceptors::Server::WorkerKillerInterceptor.new(memory_limit_min: memory_limit_min, memory_limit_max: memory_limit_max)
end

Griffin::Server.configure do |c|
  c.bind('0.0.0.0')
  c.port(port)

  c.services([
    health_check_service,
    TsukurepoService,
  ])

  c.interceptors(interceptors)
  c.workers(worker_size)
  c.pool_size(pool_min, pool_max)
  c.connection_size(connection_min, connection_max)
  c.log('-') # STDOUT
  c.log_level(Rails.logger.level)
end

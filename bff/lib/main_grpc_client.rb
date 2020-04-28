require 'main/services/v1/recipe_services_pb'
require 'main/services/v1/user_services_pb'

class MainGrpcClient
  class << self
    attr_reader :host, :port, :authority

    def configure(host:, port:, authority:)
      @host = host
      @port = port
      @authority = authority
    end

    def stub(service)
      Main::Services::V1::const_get(service.to_s.camelcase)::Stub.new(
        "#{self.host}:#{self.port}",
        :this_channel_is_insecure,
        channel_args: { 'grpc.default_authority' => self.authority },
      )
    end
  end
end

MainGrpcClient.configure(
  authority: Rails.application.config.x.grpc_service[:main][:authority],
  host: Rails.application.config.x.grpc_service[:main][:host],
  port: Rails.application.config.x.grpc_service[:main][:port],
)

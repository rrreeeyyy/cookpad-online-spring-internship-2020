require 'tsukurepo_backend/services/v1/tsukurepo_services_pb'

class TsukurepoGrpcClient
  class << self
    attr_reader :host, :port, :authority

    def configure(host:, port:, authority:)
      @host = host
      @port = port
      @authority = authority
    end

    def stub(service)
      TsukurepoBackend::Services::V1::const_get(service.to_s.camelcase)::Stub.new(
        "#{self.host}:#{self.port}",
        :this_channel_is_insecure,
        channel_args: { 'grpc.default_authority' => self.authority },
      )
    end
  end
end

TsukurepoGrpcClient.configure(
  authority: Rails.application.config.x.grpc_service[:tsukurepo_backend][:authority],
  host: Rails.application.config.x.grpc_service[:tsukurepo_backend][:host],
  port: Rails.application.config.x.grpc_service[:tsukurepo_backend][:port],
)

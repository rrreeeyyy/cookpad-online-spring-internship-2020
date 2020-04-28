# frozen_string_literal: true

namespace :protobuf do
  desc 'Generate code by grpc_tools_ruby_protoc'

  task :compile, [:service, :out] do |_, args|
    args.with_defaults(out: 'lib')
    service = args.to_h.fetch(:service)
    out = args.to_h.fetch(:out)
    proto_path = File.join(File.expand_path('../../../..', __FILE__), 'protobuf-definitions')
    proto_files = Dir.glob("#{proto_path}/#{service}/**/*.proto")
    old_pb_files = Dir.glob("#{out}/#{service}/**/*_pb.rb")
    File.delete(*old_pb_files)
    sh 'grpc_tools_ruby_protoc', '--ruby_out', out, '--grpc_out', out, '--proto_path', proto_path, *proto_files
  end
end

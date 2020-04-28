require 'main/resources/v1/user_pb'
require 'google/protobuf/well_known_types'

class User < ApplicationRecord
  has_many :recipe, dependent: :destroy

  validates :name, presence: true

  def as_protocol_buffer(request_context: nil)
    Main::Resources::V1::User.new(
      id: id,
      name: name,
      created_at: Google::Protobuf::Timestamp.new.tap {|t| t.from_time(created_at) },
      updated_at: Google::Protobuf::Timestamp.new.tap {|t| t.from_time(updated_at) },
    )
  end
end

require 'main/resources/v1/step_pb'
require 'google/protobuf/well_known_types'

class Step < ApplicationRecord
  belongs_to :recipe

  validates :description, presence: true
  validates :position, presence: true

  def as_protocol_buffer(request_context: nil)
    Main::Resources::V1::Step.new(
      description: description,
      created_at: Google::Protobuf::Timestamp.new.tap {|t| t.from_time(created_at) },
      updated_at: Google::Protobuf::Timestamp.new.tap {|t| t.from_time(updated_at) },
    )
  end
end

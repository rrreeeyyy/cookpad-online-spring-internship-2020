require 'tsukurepo_backend/resources/v1/tsukurepo_pb'
require 'google/protobuf/well_known_types'

class Tsukurepo < ApplicationRecord
  validates :recipe_id, presence: true
  validates :user_id, presence: true
  validates :comment, presence: true

  def as_protocol_buffer(request_context: nil)
    TsukurepoBackend::Resources::V1::Tsukurepo.new(
      id: id,
      recipe_id: recipe_id,
      user_id: user_id,
      comment: comment,
      created_at: Google::Protobuf::Timestamp.new.tap {|t| t.from_time(created_at) },
      updated_at: Google::Protobuf::Timestamp.new.tap {|t| t.from_time(updated_at) },
    )
  end
end


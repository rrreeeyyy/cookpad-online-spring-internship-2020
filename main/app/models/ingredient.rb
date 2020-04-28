require 'main/resources/v1/ingredient_pb'
require 'google/protobuf/well_known_types'

class Ingredient < ApplicationRecord
  belongs_to :recipe

  validates :name, presence: true
  validates :quantity, presence: true
  validates :position, presence: true

  def as_protocol_buffer(request_context: nil)
    Main::Resources::V1::Ingredient.new(
      name: name,
      quantity: quantity,
      created_at: Google::Protobuf::Timestamp.new.tap {|t| t.from_time(created_at) },
      updated_at: Google::Protobuf::Timestamp.new.tap {|t| t.from_time(updated_at) },
    )
  end
end

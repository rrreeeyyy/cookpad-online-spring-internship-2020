require 'main/resources/v1/recipe_pb'
require 'google/protobuf/well_known_types'

class Recipe < ApplicationRecord
  belongs_to :user
  has_many :ingredients, -> { order(:position) }, dependent: :destroy
  has_many :steps, -> { order(:position) }, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true

  def as_protocol_buffer(request_context: nil)
    Main::Resources::V1::Recipe.new(
      id: id,
      title: title,
      user: user&.as_protocol_buffer,
      ingredients: ingredients&.map(&:as_protocol_buffer),
      steps: steps&.map(&:as_protocol_buffer),
      description: description,
      created_at: Google::Protobuf::Timestamp.new.tap {|t| t.from_time(created_at) },
      updated_at: Google::Protobuf::Timestamp.new.tap {|t| t.from_time(updated_at) },
    )
  end
end


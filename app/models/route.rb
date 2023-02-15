# frozen_string_literal: true

# entity used to store fully qualified routes
class Route < ApplicationRecord
  belongs_to :source, polymorphic: true, inverse_of: :route

  validates :path,
            length: { within: 1..255 },
            presence: true,
            uniqueness: { case_sensitive: false }
end

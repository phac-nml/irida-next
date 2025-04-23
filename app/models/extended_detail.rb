# frozen_string_literal: true

# entity class for activity extended details
class ExtendedDetail < ApplicationRecord
  has_many :activity_extended_details, dependent: nil
  has_many :activities, through: :activity_extended_details

  validates :details, presence: true
end

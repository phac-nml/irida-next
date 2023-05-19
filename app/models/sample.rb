# frozen_string_literal: true

# entity class for Sample
class Sample < ApplicationRecord
  has_logidze
  belongs_to :project

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :name, uniqueness: { scope: %i[name project_id] }
end

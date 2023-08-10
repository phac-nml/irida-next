# frozen_string_literal: true

# entity class for Sample
class Sample < ApplicationRecord
  has_logidze
  acts_as_paranoid

  belongs_to :project

  has_many_attached :files

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :name, uniqueness: { scope: %i[name project_id] }
end

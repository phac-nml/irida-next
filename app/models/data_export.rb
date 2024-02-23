# frozen_string_literal: true

# entity class for DataExport
class DataExport < ApplicationRecord
  has_logidze
  acts_as_paranoid

  belongs_to :user

  has_one_attached :file

  validates :file, attached: true
end

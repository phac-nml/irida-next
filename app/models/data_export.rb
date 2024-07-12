# frozen_string_literal: true

# entity class for DataExport
class DataExport < ApplicationRecord
  has_logidze

  belongs_to :user

  has_one_attached :file, dependent: :purge_later

  validates :status, acceptance: { accept: %w[processing ready] }
  validates :export_type, acceptance: { accept: %w[sample analysis linelist] }
end

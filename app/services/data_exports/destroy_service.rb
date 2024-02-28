# frozen_string_literal: true

module DataExports
  # Service used to Create Attachments
  class DestroyService < BaseService
    DataExportDestroyError = Class.new(StandardError)
    def execute
      authorize! data_export, to: :destroy?

      if data_export.file
        puts 'exists'
      else
        puts 'does not exist'
      end
    rescue DataExports::CreateService::DataExportCreateError => e
      @data_export.errors.add(:base, e.message)
      false
    end
  end
end

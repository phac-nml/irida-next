# frozen_string_literal: true

module DataExports
  # Service used to Destroy Data Exports
  class DestroyService < BaseService
    class DataExportDestroyError < StandardError
    end

    def initialize(data_export, user = nil)
      super(user, {})
      @data_export = data_export
    end

    def execute
      validate_project_not_archived

      authorize! @data_export, to: :destroy?

      @data_export.destroy
    rescue DataExports::DestroyService::DataExportDestroyError => e
      @data_export.errors.add(:base, e.message)
      @data_export
    end

    private

    def validate_project_not_archived
      namespace = Namespace.find(@data_export['export_parameters']['namespace_id'])

      return unless namespace.instance_of?(Namespaces::ProjectNamespace) &&
                    namespace.archived_at.present?

      raise DataExportDestroyError,
            I18n.t('services.data_exports.destroy.project_read_only')
    end
  end
end

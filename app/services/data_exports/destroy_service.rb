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
      if @data_export['export_parameters'].present? && @data_export['export_parameters']['namespace_id'].present?
        namespace = Namespace.find_by(id: @data_export['export_parameters']['namespace_id'])
        validate_project_not_archived(namespace) if namespace&.project_namespace?
      end

      authorize! @data_export, to: :destroy?

      @data_export.destroy
    rescue DataExports::DestroyService::DataExportDestroyError => e
      @data_export.errors.add(:base, e.message)
      @data_export
    end
  end
end

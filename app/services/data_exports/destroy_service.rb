# frozen_string_literal: true

module DataExports
  # Service used to Destroy Data Exports
  class DestroyService < BaseService
    def initialize(data_export, user = nil)
      super(user, {})
      @data_export = data_export
    end

    def execute
      authorize! @data_export, to: :destroy?

      @data_export.file.purge if @data_export.file

      @data_export.destroy
    end
  end
end

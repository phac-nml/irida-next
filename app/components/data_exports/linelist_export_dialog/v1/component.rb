# frozen_string_literal: true

module DataExports
  module LinelistExportDialog
    module V1
      # Renders the existing linelist dialog partial as the v1 implementation.
      class Component < ::Component
        def initialize(open:, namespace_id:, templates:, **_system_arguments)
          @open = open
          @namespace_id = namespace_id
          @templates = templates
        end

        def call
          render(partial: 'data_exports/new_linelist_export_dialog',
                 locals: { open: @open, namespace_id: @namespace_id, templates: @templates })
        end
      end
    end
  end
end

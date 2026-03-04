# frozen_string_literal: true

module DataExports
  module LinelistExportDialog
    module V2
      # Client-side linelist export dialog implementation.
      class Component < V1::Component
        def initialize(open:, namespace_id:, templates:, **system_arguments)
          @open = open
          @namespace_id = namespace_id
          @templates = templates
          @system_arguments = system_arguments
        end

        def call
          render(partial: 'data_exports/new_linelist_export_dialog_v2',
                 locals: { open: @open, namespace_id: @namespace_id, templates: @templates })
        end
      end
    end
  end
end

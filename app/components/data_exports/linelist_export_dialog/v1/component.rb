# frozen_string_literal: true

module DataExports
  module LinelistExportDialog
    module V1
      # Renders the existing linelist dialog partial as the v1 implementation.
      class Component < ::Component
        def initialize(open:, namespace_id:, namespace:, templates:, data_export: nil, selected: false,
                       **_system_arguments) # rubocop:disable Metrics/ParameterLists
          @open = open
          @namespace_id = namespace_id
          @namespace = namespace
          @templates = templates
          @data_export = data_export
          @selected = selected
        end

        def call
          render(partial: 'data_exports/new_linelist_export_dialog',
                 locals: { open: @open, namespace: @namespace, namespace_id: @namespace_id, templates: @templates,
                           data_export: @data_export, selected: @selected })
        end
      end
    end
  end
end

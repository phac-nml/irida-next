# frozen_string_literal: true

module DataExports
  module LinelistExportDialog
    module V2
      # Client-side linelist export dialog implementation.
      class Component < V1::Component
        def initialize(open:, namespace_id:, namespace:, templates:, **system_arguments)
          @open = open
          @namespace_id = namespace_id
          @namespace = namespace
          @templates = templates
          @system_arguments = system_arguments
        end
      end
    end
  end
end

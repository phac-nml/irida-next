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

        def graphql_url
          helpers.api_graphql_path
        end

        def upload_url
          helpers.upload_data_exports_path
        end

        def sample_graphql_id_prefix
          "gid://#{GlobalID.app}/Sample/"
        end
      end
    end
  end
end

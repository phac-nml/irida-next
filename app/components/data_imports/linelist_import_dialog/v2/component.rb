# frozen_string_literal: true

module DataImports
  module LinelistImportDialog
    module V2
      # Client-side linelist import dialog implementation.
      class Component < ::Component
        def initialize(broadcast_target:, group: nil, project: nil, **_system_arguments)
          @broadcast_target = broadcast_target
          @group = group
          @project = project
        end

        def graphql_url
          helpers.api_graphql_path
        end
      end
    end
  end
end

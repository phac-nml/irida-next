# frozen_string_literal: true

module DataImports
  module LinelistImportDialog
    module V1
      # Renders the existing linelist import dialog partial as the v1 implementation.
      class Component < ::Component
        def initialize(broadcast_target:, open:, url:, **_system_arguments)
          @broadcast_target = broadcast_target
          @open = open
          @url = url
        end

        def call
          render(partial: 'shared/samples/metadata/file_imports/dialog',
                 locals: { broadcast_target: @broadcast_target, open: @open, url: @url })
        end
      end
    end
  end
end

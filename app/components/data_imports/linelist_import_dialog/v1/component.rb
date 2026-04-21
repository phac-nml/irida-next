# frozen_string_literal: true

module DataImports
  module LinelistImportDialog
    module V1
      # Renders the existing linelist import dialog partial as the v1 implementation.
      class Component < ::Component
        def initialize(open:, url:, closable:, **_system_arguments)
          @open = open
          @url = url
          @closable = closable
        end

        def call
          render(partial: 'shared/samples/metadata/file_imports/dialog',
                 locals: { open: @open, url: @url, closable: @closable })
        end
      end
    end
  end
end

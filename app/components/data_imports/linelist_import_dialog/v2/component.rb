# frozen_string_literal: true

module DataImports
  module LinelistImportDialog
    module V2
      # Client-side linelist import dialog implementation.
      class Component < ::Component
        def initialize(broadcast_target:, open:, **_system_arguments)
          @broadcast_target = broadcast_target
          @open = open
        end
      end
    end
  end
end

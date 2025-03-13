# frozen_string_literal: true

module Viral
  module Dialog
    # Header component for dialog dialog
    class HeaderComponent < Viral::BaseComponent
      attr_reader :title, :closable

      def initialize(title:, closable: true, **system_arguments)
        @title = title
        @closable = closable
        @system_arguments = system_arguments

        @system_arguments[:classes] =
          class_names(@system_arguments[:classes],
                      'flex items-start justify-between rounded-t border-b border-slate-200 p-5 dark:border-slate-600')
      end
    end
  end
end

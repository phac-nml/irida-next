# frozen_string_literal: true

module Viral
  module Dialog
    # Header component for dialog dialog
    class HeaderComponent < Viral::BaseComponent
      attr_reader :title, :closable

      def initialize(title:, closable: true)
        @title = title
        @closable = closable
        @system_arguments = {}
        @system_arguments[:classes] =
          class_names(@system_arguments[:classes],
                      'flex items-start justify-between p-5 border-b rounded-t dark:border-slate-600')
      end
    end
  end
end

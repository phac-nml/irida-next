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
                      'dialog--header flex items-start justify-between rounded-t p-5')
      end
    end
  end
end

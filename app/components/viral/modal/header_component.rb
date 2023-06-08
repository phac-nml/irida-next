# frozen_string_literal: true

module Viral
  module Modal
    class HeaderComponent < Viral::BaseComponent
      attr_reader :title

      def initialize(title:)
        @title = title
        @system_arguments = {}
        @system_arguments[:classes] = class_names(@system_arguments[:classes], 'dialog--header')
      end
    end
  end
end

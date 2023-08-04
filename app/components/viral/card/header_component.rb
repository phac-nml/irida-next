# frozen_string_literal: true

module Viral
  module Card
    # Header component for the card
    class HeaderComponent < Component
      attr_reader :subtitle, :title

      renders_many :actions

      def initialize(title: '', subtitle: nil, **system_arguments)
        @title = title
        @subtitle = subtitle
        @system_arguments = system_arguments
        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          'p-4'
        )
      end

      def title_only?
        content.blank? && actions.blank?
      end
    end
  end
end

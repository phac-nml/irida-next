# frozen_string_literal: true

module Viral
  module Card
    # Header component for the card
    class HeaderComponent < Component
      attr_reader :subtitle, :title, :title_id

      renders_many :actions

      def initialize(title_id: nil, title: '', subtitle: nil, **system_arguments)
        @title = title
        @title_id = title_id
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

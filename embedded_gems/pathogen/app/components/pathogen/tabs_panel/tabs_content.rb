# frozen_string_literal: true

module Pathogen
  class TabsPanel
    # 📝 TabsContent: Renders a single tab panel's content
    class TabsContent < Pathogen::Component
      def initialize(id:, labelledby:, selected: false)
        @id = id
        @labelledby = labelledby
        @selected = selected
      end

      def call
        content_tag(
          :div,
          content,
          id: @id,
          class: class_names('mt-4', 'hidden' => !@selected),
          role: 'tabpanel',
          aria: { labelledby: @labelledby },
          hidden: !@selected
        )
      end
    end
  end
end

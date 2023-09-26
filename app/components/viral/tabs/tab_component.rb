# frozen_string_literal: true

module Viral
  module Tabs
    class TabComponent < Viral::Component
      attr_reader :url, :label, :link_classes, :selected

      erb_template <<-ERB
        <%= link_to label, url, class: link_classes, data: { turbo_frame: "_top" } %>
      ERB

      def initialize(url:, label:, selected: false)
        @url = url
        @label = label
        @selected = selected
        @link_classes = class_names({
                                      'inline-block p-4 border-b-2 rounded-t-lg': selected,
                                      'inline-block p-4 border-b-2 border-transparent rounded-t-lg hover:text-gray-600 hover:border-gray-300 dark:hover:text-gray-300': !selected
                                    })
      end
    end
  end
end

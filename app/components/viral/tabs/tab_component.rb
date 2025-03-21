# frozen_string_literal: true

module Viral
  module Tabs
    # A tab component for use with the Viral::Tabs::TabsComponent.
    class TabComponent < Viral::Component
      erb_template <<-ERB
        <%= link_to @url, class: @link_classes, role: "tab", aria: @aria do %>
          <%= content %>
        <% end %>
      ERB

      def initialize(url:, controls: nil, selected: false)
        @url = url
        @selected = selected
        @link_classes = class_names(
          'inline-block p-4 border-b-2 rounded-t-lg',
          {
            'text-primary-700 border-primary-700 active dark:text-primary-500 dark:border-primary-500': selected,
            'border-transparent hover:text-slate-600 hover:border-slate-300 dark:hover:text-slate-300': !selected
          }
        )
        @aria = { selected: @selected }
        @aria[:controls] = controls if controls.present?
      end
    end
  end
end

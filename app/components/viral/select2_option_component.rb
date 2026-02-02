# frozen_string_literal: true

module Viral
  # Search component for rendering a searchable dropdown
  class Select2OptionComponent < Viral::Component
    erb_template <<~ERB
      <li
        class="flex flex-col text-left p-2.5 rounded-lg bg-slate-50 hover:bg-slate-200 dark:bg-slate-700 dark:hover:bg-slate-600
               cursor-pointer mx-0.5 my-0.5 border hover:border-slate-500 dark:hover:border-slate-600"
        role="option"
        aria-selected="false"
        id="select2-option-<%= @value %>"
        role="option"
        data-<%= controller_name %>-target="item"
        data-label="<%= @label %>"
        data-value="<%= @value %>"
        data-action="click-><%= controller_name %>#select keydown-><%= controller_name %>#keydown"
      >
        <%= content %>
      </li>
    ERB

    def initialize(value:, label:)
      @value = value
      @label = label
    end

    def controller_name
      if Flipper.enabled?(:beta_dropdown)
        'viral--beta-select2'
      else
        'viral--select2'
      end
    end
  end
end

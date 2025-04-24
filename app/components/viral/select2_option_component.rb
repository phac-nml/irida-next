# frozen_string_literal: true

module Viral
  # Search component for rendering a searchable dropdown
  class Select2OptionComponent < Viral::Component
    erb_template <<~ERB
      <li
        class="flex flex-col text-left p-2.5 rounded bg-slate-50 hover:bg-slate-200 dark:bg-slate-700 dark:hover:bg-slate-600
               cursor-pointer mx-0.5 my-0.5 border hover:border-slate-500 dark:hover:border-slate-600"
        role="option"
        aria-selected="false"
        id="select2-option-<%= @value %>"
        role="option"
        data-viral--select2-target="item"
        data-label="<%= @label %>"
        data-value="<%= @value %>"
        data-action="click->viral--select2#select keydown->viral--select2#keydown"
      >
        <%= content %>
      </li>
    ERB

    def initialize(value:, label:)
      @value = value
      @label = label
    end
  end
end

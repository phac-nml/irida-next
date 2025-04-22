# frozen_string_literal: true

module Viral
  # Search component for rendering a searchable dropdown
  class Select2OptionComponent < Viral::Component
    erb_template <<~ERB
      <li
        class="flex flex-col text-left p-2.5 rounded-md bg-slate-50 hover:bg-slate-100 dark:bg-slate-700 dark:hover:bg-slate-600
               cursor-pointer border border-transparent transition-colors duration-150 mx-0.5 my-0.5"
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

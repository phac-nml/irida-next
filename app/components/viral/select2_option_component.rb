# frozen_string_literal: true

module Viral
  # Search component for rendering a searchable dropdown
  class Select2OptionComponent < Viral::Component
    erb_template <<~ERB
      <li class="w-full">
          <button
            type="button"
            data-viral--select2-target="item"
            data-label="<%= @label %>"
            data-value="<%= @value %>"
            data-action="click->viral--select2#select"
            class="
              flex-col w-full border-2 border-transparent text-left p-2.5 bg-slate-50 hover:bg-slate-100
              dark:bg-slate-700 dark:hover:bg-slate-600
            "
          >
            <%= content %>
          </button>
        </li>
    ERB

    def initialize(value:, label:)
      @value = value
      @label = label
    end
  end
end

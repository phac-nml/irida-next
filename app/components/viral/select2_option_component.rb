# fr# frozen_string_literal: true

module Viral
  # Search component for rendering a searchable dropdown
  class Select2OptionComponent < Viral::Component
    erb_template <<~ERB
      <li class="w-full">
          <button
            type="button"
            data-viral--select2-target="item"
            data-viral--select2-primary-param="<%= @primary %>"
            data-viral--select2-secondary-param="<%= @secondary %>"
            data-viral--select2-value-param="<%= @value %>"
            data-action="click->viral--select2#select"
            class="
              flex-col w-full border-2 border-transparent text-left p-2.5 hover:bg-slate-100
              dark:hover:bg-slate-600 focus:outline-none focus:bg-slate-100
            "
          >
            <span
              class="block text-base font-medium truncate text-slate-900 dark:text-white"
            >
              <%= @primary %>
            </span>
            <% if @secondary %>
            <span class="text-sm truncate text-slate-500 dark:text-slate-400">
              <%= @secondary %>
            </span>
            <% end %>
          </button>
        </li>
    ERB

    def initialize(primary:, value:, secondary: nil)
      @primary = primary
      @secondary = secondary
      @value = value
    end
  end
end

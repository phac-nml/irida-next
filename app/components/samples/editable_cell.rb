# frozen_string_literal: true

module Samples
  # Component for rendering an editable cell
  class EditableCell < Component
    with_collection_parameter :field

    erb_template <<~ERB
      <td id="<%= dom_id(@sample, @field) %>"
          class="relative"
          role="gridcell">
        <%= form_with(
              url: editable_namespace_project_sample_metadata_field_path(
                @sample.project.namespace.parent,
                @sample.project,
                @sample
              ),
              method: :get,
              class: "w-full"
            ) do |form| %>

          <%= form.hidden_field :field, value: @field %>
          <%= form.hidden_field :format, value: "turbo_stream" %>

          <button type="submit"
                  class="w-full p-4 text-left cursor-pointer hover:bg-slate-50 focus:ring-4 focus:outline-none focus:ring-primary-200 dark:hover:bg-slate-600 dark:focus:ring-primary-700"
                  aria-label="Edit <%= @field %> value"
                  <%= "autofocus" if @autofocus %>>
            <span class="block truncate">
              <%= @sample.metadata[@field] || "" %>
            </span>
          </button>
        <% end %>
      </td>
    ERB

    def initialize(field:, sample:, autofocus: false)
      @sample = sample
      @field = field
      @autofocus = autofocus
    end
  end
end

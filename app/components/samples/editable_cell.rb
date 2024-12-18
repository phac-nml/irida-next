# frozen_string_literal: true

module Samples
  # Component for rendering an editable cell
  class EditableCell < Component
    with_collection_parameter :field

    erb_template <<~ERB
      <td id="<%= dom_id(@sample, @field) %>">
        <%= form_with(url: editable_namespace_project_sample_metadata_field_path(@sample.project.namespace.parent, @sample.project, @sample), method: :get) do |form| %>
          <%= form.hidden_field :field, value: @field %>
          <%= form.hidden_field :format, value: "turbo_stream" %>
          <%= form.submit @sample.metadata[@field]  || "", class: "cursor-pointer p-4 hover:bg-slate-50 dark:hover:bg-slate-600 focus:ring-4 focus:outline-none focus:ring-primary-200 dark:focus:ring-primary-700 w-full text-left", autofocus: @autofocus %>
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

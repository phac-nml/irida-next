# frozen_string_literal: true

module Samples
  # Component for rendering an editable cell
  class EditableCell < Component
    with_collection_parameter :field

    erb_template <<~ERB
      <td id="<%= dom_id(@sample, @field) %>">
        <%= form_with(url: @check_editable_url, method: :get) do |form| %>
          <%= form.hidden_field :id, value: @sample.id %>
          <%= form.hidden_field :field, value: @field %>
          <%= form.hidden_field :value, value: @value %>
          <%= form.hidden_field :format, value: "turbo_stream" %>
          <%= form.submit @value, class: "cursor-pointer p-4 hover:bg-slate-50 dark:hover:bg-slate-600 w-full text-left" %>
        <% end %>
      </td>
    ERB

    def initialize(field:, sample:, check_editable_url:)
      @sample = sample
      @field = field
      @value = sample.metadata[field]
      @check_editable_url = check_editable_url
    end
  end
end

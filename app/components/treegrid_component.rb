# frozen_string_literal: true

# Treegrid component
class TreegridComponent < Component
  erb_template <<-ERB
    <div class="treegrid-container" data-controller="treegrid" aria-role="treegrid" aria-readonly="true">
      <% rows.each do |row| %>
        <%= row %>
      <% end %>
    </div>
  ERB

  renders_many :rows, Treegrid::RowComponent
end

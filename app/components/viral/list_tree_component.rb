# frozen_string_literal: true

module Viral
  # Root component for the list tree
  class ListTreeComponent < Viral::Component
    erb_template <<-ERB
      <div class="groups-list-tree-component">
        <%= render(Viral::ListTree::TreeComponent.new) do %>
          <%= content %>
        <% end %>
      </div>
    ERB
  end
end

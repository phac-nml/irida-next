# frozen_string_literal: true

module GroupsList
  class GroupListTreeComponent < ViewComponent::Base
    LIMIT = 10

    erb_template <<~ERB
      <ul class="groups-list group-list-tree flex flex-col">
        <%= render GroupsList::GroupRowComponent.with_collection(@groups.take(LIMIT), path: @path, path_args: @path_args, collapsed: @collapsed) %>
        <% if @groups.count > LIMIT %>
          <li class="group-row">MOREITEMS HERE</li>
        <% end %>
      </ul>
    ERB

    def initialize(groups:, path: nil, path_args: {})
      @groups = groups
      @path = path
      @path_args = path_args
      @collapsed = true
    end
  end
end

# frozen_string_literal: true

module GroupsList
  class GroupRowComponent < ViewComponent::Base
    with_collection_parameter :group

    erb_template <<~ERB
      <% if @group.children.any? %>
        <%= render GroupsList::GroupRow::WithChildrenComponent.new(group: @group, path: @path, path_args: @path_args, collapsed: @collapsed) %>
        <% else %>
        <%= render GroupsList::GroupRow::WithoutChildrenComponent.new(group: @group, path: @path, path_args: @path_args) %>
      <% end %>
    ERB

    def initialize(group:, path: nil, path_args: {}, collapsed: true)
      @group = group
      @path = path
      @path_args = path_args
      @collapsed = collapsed
    end
  end
end

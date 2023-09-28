# frozen_string_literal: true

module NamespaceTree
  # This component renders a group row, either with or without children.
  class RowComponent < ViewComponent::Base
    with_collection_parameter :group

    erb_template <<~ERB
      <% if @group.direct_descendants_of_type?(@type) %>
        <%= render NamespaceTree::Row::WithChildrenComponent.new(group: @group, type: @type, children: Group.none, path: @path, path_args: @path_args, collapsed: @collapsed) %>
        <% else %>
        <%= render NamespaceTree::Row::WithoutChildrenComponent.new(group: @group, path: @path, path_args: @path_args) %>
      <% end %>
    ERB

    def initialize(group:, type:, path: nil, path_args: {}, collapsed: true)
      @group = group
      @type = type
      @path = path
      @path_args = path_args
      @collapsed = collapsed
    end
  end
end

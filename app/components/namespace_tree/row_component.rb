# frozen_string_literal: true

module NamespaceTree
  # This component renders a namespace row, either with or without children.
  class RowComponent < ViewComponent::Base
    with_collection_parameter :namespace

    erb_template <<~ERB
      <% if @namespace.children_of_type?(@type) && !@flat %>
        <%= render NamespaceTree::Row::WithChildrenComponent.new(namespace: @namespace, type: @type, children: Group.none, path: @path, path_args: @path_args, collapsed: @collapsed) %>
        <% else %>
        <%= render NamespaceTree::Row::WithoutChildrenComponent.new(namespace: @namespace, path: @path, path_args: @path_args) %>
      <% end %>
    ERB

    def initialize(namespace:, type:, path: nil, path_args: {}, collapsed: true, flat: false)
      @namespace = namespace
      @type = type
      @path = path
      @path_args = path_args
      @collapsed = collapsed
      @flat = flat
    end
  end
end

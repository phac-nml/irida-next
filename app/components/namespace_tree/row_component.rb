# frozen_string_literal: true

module NamespaceTree
  # This component renders a namespace row, either with or without children.
  class RowComponent < ViewComponent::Base
    with_collection_parameter :namespace

    erb_template <<~ERB
      <% if @namespace.children_of_type?(@type) && !@render_flat_list %>
        <%= render NamespaceTree::Row::WithChildrenComponent.new(namespace: @namespace, type: @type, children: Group.none, path: @path, path_args: @path_args, collapsed: @collapsed, icon_size: @icon_size) %>
        <% else %>
        <%= render NamespaceTree::Row::WithoutChildrenComponent.new(namespace: @namespace, path: @path, path_args: @path_args, icon_size: @icon_size, search_params: @search_params) %>
      <% end %>
    ERB

    # rubocop:disable Metrics/ParameterLists
    def initialize(namespace:, type:, path: nil, path_args: {}, collapsed: true, render_flat_list: false,
                   search_params: nil, icon_size: :small)
      @namespace = namespace
      @type = type
      @path = path
      @path_args = path_args
      @collapsed = collapsed
      @render_flat_list = render_flat_list
      @search_params = search_params
      @icon_size = icon_size
    end

    # rubocop:enable Metrics/ParameterLists
  end
end

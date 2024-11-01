# frozen_string_literal: true

# Renders top level wrapper for the namespace tree
class NamespaceTreeContainerComponent < ViewComponent::Base
  erb_template <<-ERB
      <div class="namespace-tree-container">
        <%= render NamespaceTree::NamespaceTreeComponent.new(namespaces: @namespaces, path: @path, path_args: @path_args, type: @type, render_flat_list: @render_flat_list, icon_size: @icon_size, search_params: @search_params) %>
      </div>
  ERB

  # rubocop: disable Metrics/ParameterLists
  def initialize(namespaces:, path: nil, path_args: {}, type: Group.sti_name, render_flat_list: false,
                 icon_size: :small, search_params: nil)
    @namespaces = namespaces
    @path = path
    @path_args = path_args
    @type = type
    @render_flat_list = render_flat_list
    @icon_size = icon_size
    @search_params = search_params
  end
  # rubocop: enable Metrics/ParameterLists
end

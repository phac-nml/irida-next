# frozen_string_literal: true

# Renders top level wrapper for the namespace tree
class NamespaceTreeContainerComponent < ViewComponent::Base
  erb_template <<-ERB
      <div class="namespace-tree-container">
        <%= render NamespaceTree::NamespaceTreeComponent.new(namespaces: @namespaces, path: @path, path_args: @path_args, type: @type, render_flat_list: @render_flat_list) %>
      </div>
  ERB

  def initialize(namespaces:, path: nil, path_args: {}, type: Group.sti_name, render_flat_list: false)
    @namespaces = namespaces
    @path = path
    @path_args = path_args
    @type = type
    @render_flat_list = render_flat_list
  end
end

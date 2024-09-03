# frozen_string_literal: true

# Renders top level wrapper for the namespace tree
class NamespaceTreeContainerComponent < ViewComponent::Base
  erb_template <<-ERB
      <div class="namespace-tree-container">
        <%= render NamespaceTree::NamespaceTreeComponent.new(namespaces: @namespaces, path: @path, path_args: @path_args, type: @type, flat: @flat) %>
      </div>
  ERB

  def initialize(namespaces:, path: nil, path_args: {}, type: Group.sti_name, flat: false)
    @namespaces = namespaces
    @path = path
    @path_args = path_args
    @type = type
    @flat = flat
  end
end

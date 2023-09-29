# frozen_string_literal: true

# Renders top level wrapper for the namespace tree
class NamespaceTreeContainerComponent < ViewComponent::Base
  erb_template <<-ERB
      <div class="groups-list-tree-container">
        <%= render NamespaceTree::NamespaceTreeComponent.new(groups: @groups, path: @path, path_args: @path_args, type: @type) %>
      </div>
  ERB

  def initialize(groups:, path: nil, path_args: {}, type: Group.sti_name)
    @groups = groups
    @path = path
    @path_args = path_args
    @type = type
  end
end

# frozen_string_literal: true

# This component renders a list of groups in a tree view.
class GroupListComponent < Component
  erb_template <<-ERB
      <div class="groups-list-tree-container">
        <%= render GroupList::GroupListTreeComponent.new(groups: @groups, path: @path, path_args: @path_args) %>
      </div>
  ERB

  def initialize(groups:, path: nil, path_args: {})
    @groups = groups
    @path = path
    @path_args = path_args
  end
end

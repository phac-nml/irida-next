# frozen_string_literal: true

# This component renders a list of groups in a tree view.
class GroupListComponent < Component
  erb_template <<-ERB
      <div class="groups-list-tree-container">
        <%= render GroupList::GroupListTreeComponent.new(groups: @groups) %>
      </div>
  ERB

  def initialize(groups:)
    @groups = groups
  end
end

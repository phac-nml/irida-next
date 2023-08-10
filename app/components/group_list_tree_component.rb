# frozen_string_literal: true

# This component renders a tree view of groups.
class GroupListTreeComponent < ViewComponent::Base
  erb_template <<-ERB
      <div class="groups-list-tree-component">
        <ul>
          <%= render GroupListTree::GroupRowComponent.with_collection(@groups) %>
        </ul>
      </div>
  ERB

  def initialize(groups:)
    @groups = groups
  end

  def render?
    @groups.any?
  end
end

# frozen_string_literal: true

module GroupList
  # This component renders a tree view of groups.
  class GroupListTreeComponent < ViewComponent::Base
    erb_template <<-ERB
      <ul class="groups-list group-list-tree">
        <%= render GroupList::GroupRowComponent.with_collection(@groups) %>
      </ul>
    ERB

    def initialize(groups:)
      @groups = groups
    end
  end
end

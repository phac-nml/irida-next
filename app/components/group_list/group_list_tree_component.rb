# frozen_string_literal: true

module GroupList
  # This component renders a tree view of groups.
  class GroupListTreeComponent < ViewComponent::Base
    erb_template <<-ERB
      <ul class="groups-list group-list-tree">
        <%= render GroupList::GroupRowComponent.with_collection(@groups, path: @path, path_args: @path_args) %>
      </ul>
    ERB

    def initialize(groups:, path: nil, path_args: {})
      @groups = groups
      @path = path
      @path_args = path_args
    end
  end
end

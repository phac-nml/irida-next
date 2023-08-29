# frozen_string_literal: true

class GroupsListTreeContainerComponent < ViewComponent::Base
  erb_template <<-ERB
      <div class="groups-list-tree-container">
        <%= render GroupsList::GroupListTreeComponent.new(groups: @groups, path: @path, path_args: @path_args) %>
      </div>
  ERB

  def initialize(groups:, path: nil, path_args: {})
    @groups = groups
    @path = path
    @path_args = path_args
  end
end

# frozen_string_literal: true

module Members
  # Component for rendering an access level drop-down list
  class AccessLevelComponent < Component
    def initialize(namespace, member, access_levels)
      @namespace = namespace
      @member = member
      @access_levels = access_levels
    end

    def select_member_path(id)
      if @namespace.type == 'Group'
        group_member_path(id)
      else
        namespace_project_member_path(id)
      end
    end
  end
end

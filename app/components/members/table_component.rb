# frozen_string_literal: true

module Members
  # Component for rendering a table of members
  class TableComponent < Component
    include Ransack::Helpers::FormHelper
    include MembersHelper

    # rubocop:disable Naming/MethodParameterName, Metrics/ParameterLists
    def initialize(namespace, members, access_levels, q, current_user, abilities = {})
      @namespace = namespace
      @members = members
      @access_levels = access_levels
      @q = q
      @current_user = current_user
      @abilities = abilities
      @columns = columns
    end
    # rubocop:enable Naming/MethodParameterName, Metrics/ParameterLists

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('relative overflow-x-auto'),
        data: { turbo: :temporary }
      }
    end

    def row_arguments(member)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
        args[:id] = dom_id(member)
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    def select_member_path(member)
      if @namespace.type == 'Group'
        group_member_path(@namespace, member)
      else
        namespace_project_member_path(@namespace.parent, @namespace.project, member)
      end
    end

    def access_level
      if @namespace.type == 'Group'
        'groups/members/access_level'
      else
        'projects/members/access_level'
      end
    end

    def current_user_is_member
      if @namespace.type == 'Group'
        'groups/members/current_user_is_member'
      else
        'projects/members/current_user_is_member'
      end
    end

    def current_user_is_not_member
      if @namespace.type == 'Group'
        'groups/members/current_user_is_not_member'
      else
        'projects/members/current_user_is_not_member'
      end
    end

    private

    def columns
      %i[user_email access_level namespace_name created_at expires_at]
    end
  end
end

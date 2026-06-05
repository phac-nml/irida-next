# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module Members
  # Component for rendering a table of members
  class TableComponent < Component
    include Ransack::Helpers::FormHelper
    include MembersHelper

    # rubocop:disable Naming/MethodParameterName, Metrics/ParameterLists
    def initialize(namespace, members, access_levels, q, has_members, current_user, abilities = {})
      @namespace = namespace
      @members = members
      @access_levels = access_levels
      @q = q
      @has_members = has_members
      @current_user = current_user
      @abilities = abilities
      @columns = columns
    end
    # rubocop:enable Naming/MethodParameterName, Metrics/ParameterLists

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('table-container relative overflow-x-auto')
      }
    end

    def row_arguments(member)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white dark:bg-slate-800', 'border-b border-slate-200 dark:border-slate-700')
        args[:id] = dom_id(member)
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    def current_user_is_member
      if @namespace.group_namespace?
        'groups/members/current_user_is_member'
      else
        'projects/members/current_user_is_member'
      end
    end

    def current_user_is_not_member
      if @namespace.group_namespace?
        'groups/members/current_user_is_not_member'
      else
        'projects/members/current_user_is_not_member'
      end
    end

    def update_member
      if @namespace.group_namespace?
        'groups/members/update'
      else
        'projects/members/update'
      end
    end

    private

    def columns
      %i[user_email access_level namespace_name created_at expires_at]
    end
  end
end

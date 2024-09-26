# frozen_string_literal: true

module Groups
  # Controller actions for group subgroups and projects
  class SubgroupsController < ApplicationController
    before_action :group, only: %i[index]

    def index
      authorize! @group, to: :read?
      render_subgroup
    end

    private

    def render_subgroup
      @group = Group.find(params[:parent_id])
      @collapsed = params[:collapse] == 'true'
      @children = @collapsed ? Namespace.none : namespace_children
      @depth = params[:depth].to_i
      render :subgroup
    end

    def group
      @group ||= Group.find_by_full_path(request.params[:group_id] || request.params[:id]) # rubocop:disable Rails/DynamicFindBy
    end

    def namespace_children
      @group.children_of_type(
        [
          Namespaces::ProjectNamespace.sti_name, Group.sti_name
        ]
      )
    end
  end
end

# frozen_string_literal: true

module Groups
  # Controller actions for group subgroups and projects
  class SubgroupsController < Groups::ApplicationController
    before_action :group, only: %i[index]

    def index
      authorize! @group, to: :read?
      render_subgroup
    end

    private

    def render_subgroup
      @group = Group.find(params.expect(:parent_id))
      @children = namespace_children
      @level = params[:level].to_i
      @posinset = params[:posinset].to_i
      @setsize = params[:setsize].to_i
      @tabindex = params[:tabindex].to_i
      set_namespace_row_data
      render :subgroup
    end

    def set_namespace_row_data
      @namespace_row_data = NamespaceRowPresenter.build_collection(namespaces: [@group, *@children], user: current_user)
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

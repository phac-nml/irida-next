# frozen_string_literal: true

module Groups
  # Controller actions for projects shared with a group
  class SharedProjectsController < Groups::ApplicationController
    before_action :group, only: %i[index]

    def index
      respond_to do |format|
        format.html { redirect_to group_path(@group) }
        format.turbo_stream do
          @shared_projects = @group.shared_projects
        end
      end
    end

    private

    def group
      @group ||= Group.find_by_full_path(request.params[:group_id] || request.params[:id]) # rubocop:disable Rails/DynamicFindBy
    end
  end
end

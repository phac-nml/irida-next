# frozen_string_literal: true

module Groups
  # Controller actions for Groups::ShareController
  class ShareController < Groups::ApplicationController
    before_action :group

    def create # rubocop:disable Metrics/AbcSize
      namespace_group_link = Groups::ShareService.new(current_user, params[:shared_group_id], @group,
                                                      params[:group_access_level]).execute
      if namespace_group_link
        if namespace_group_link.errors.full_messages.count.positive?
          flash[:error] = namespace_group_link.errors.full_messages.first
          render 'groups/edit', locals: { group: @group }, status: :conflict
        else
          flash[:success] = 'Successfully shared group with group'
          redirect_to group_path(@group)
        end
      else
        flash[:error] = 'There was an error sharing group with group'
        render 'groups/edit', locals: { group: @group }, status: :unprocessable_entity
      end
    end

    private

    def group
      @group ||= Group.find_by_full_path(request.params[:group_id] || request.params[:id]) # rubocop:disable Rails/DynamicFindBy
    end

    def share_params
      params.permit(:shared_group_id)
    end
  end
end

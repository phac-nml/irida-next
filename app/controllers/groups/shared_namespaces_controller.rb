# frozen_string_literal: true

module Groups
  # Controller actions for projects shared with a group
  class SharedNamespacesController < Groups::ApplicationController
    before_action :group, only: %i[index]

    def index
      authorize! @group, to: :read?
      respond_to do |format|
        format.html { redirect_to group_path(@group) }
        format.turbo_stream do
          @namespaces = @group.shared_namespaces
        end
      end
    end

    private

    def group
      @group ||= Group.find_by_full_path(request.params[:group_id] || request.params[:id]) # rubocop:disable Rails/DynamicFindBy
    end
  end
end

# frozen_string_literal: true

module Groups
  # Controller actions for projects shared with a group
  class SharedNamespacesController < Groups::ApplicationController
    before_action :group, only: %i[index search]

    def index
      authorize! @group, to: :read?
      respond_to do |format|
        format.html { redirect_to group_path(@group) }
        format.turbo_stream do
          @q = @group.shared_namespaces.ransack(params[:q])
          @q.sorts = 'created_at desc' if @q.sorts.empty?
          @pagy, @namespaces = pagy(@q.result)
        end
      end
    end

    def search
      redirect_to group_shared_namespaces_path
    end

    private

    def group
      @group ||= Group.find_by_full_path(request.params[:group_id] || request.params[:id]) # rubocop:disable Rails/DynamicFindBy
    end
  end
end

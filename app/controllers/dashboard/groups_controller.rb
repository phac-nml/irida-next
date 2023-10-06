# frozen_string_literal: true

module Dashboard
  # Dashboard groups controller
  class GroupsController < ApplicationController
    def index
      @q = Group.ransack(params[:q])
      set_default_sort
      respond_to do |format|
        format.html
        format.turbo_stream do
          if toggling_group?
            toggle_group
            render :group
          else
            @pagy, @groups = pagy(@q.result.where(id: load_groups.select(:id)).include_route)
          end
        end
      end
    end

    private

    def set_default_sort
      @q.sorts = 'created_at desc' if @q.sorts.empty?
    end

    def toggling_group?
      params.key? :parent_id
    end

    def toggle_group
      @collapsed = params[:collapse] == 'true'
      @group = Group.find(params[:parent_id])
      @depth = params[:depth].to_i
      return if @collapsed

      @sub_groups = @group.children
    end

    def load_groups
      @groups = authorized_scope(Group, type: :relation).without_descendants
    end
  end
end

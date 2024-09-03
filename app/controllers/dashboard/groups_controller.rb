# frozen_string_literal: true

module Dashboard
  # Dashboard groups controller
  class GroupsController < ApplicationController
    before_action :current_page

    def index
      @flat = params[:q].present? && params[:q][:name_or_puid_cont].present?
      @q = authorized_groups.ransack(params[:q])
      set_default_sort
      @pagy, @groups = pagy(@q.result.include_route)
      respond_to do |format|
        format.html
        format.turbo_stream do
          if toggling_group?
            toggle_group
            render :group
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
      @children = Group.none
      return if @collapsed

      @children = @group.children
    end

    def authorized_groups
      if @flat
        authorized_scope(Group, type: :relation)
      else
        authorized_scope(Group, type: :relation).without_descendants
      end
    end

    def current_page
      @current_page = t(:'general.default_sidebar.groups')
    end
  end
end

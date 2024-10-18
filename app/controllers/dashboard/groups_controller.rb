# frozen_string_literal: true

module Dashboard
  # Dashboard groups controller
  class GroupsController < ApplicationController
    before_action :current_page

    def index
      @q = build_ransack_query
      set_default_sort
      @pagy, @groups = pagy(@q.result.include_route)
      respond_to_format
    end

    private

    def flat_list_requested?
      params.dig(:q, :name_or_puid_cont).present?
    end

    def build_ransack_query
      @search_params = params[:q] || {}
      authorized_groups.ransack(@search_params)
    end

    def respond_to_format
      respond_to do |format|
        format.html
        format.turbo_stream { handle_turbo_stream }
      end
    end

    def handle_turbo_stream
      toggle_group if toggling_group?
      render :group if toggling_group?
    end

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
      if flat_list_requested?
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

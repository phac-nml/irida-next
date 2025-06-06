# frozen_string_literal: true

module Dashboard
  # Dashboard groups controller
  class GroupsController < ApplicationController
    before_action :current_page
    before_action :render_flat_list, only: %i[index]
    before_action :page_title

    def index
      @q = build_ransack_query
      set_default_sort
      @pagy, @groups = pagy(@q.result.include_route)
      respond_to_format
    end

    private

    def render_flat_list
      @render_flat_list = params.dig(:q, :name_or_puid_cont).present?
    end

    def build_ransack_query
      authorized_groups.ransack(params[:q])
    end

    def respond_to_format
      respond_to do |format|
        format.html
        format.turbo_stream { handle_turbo_stream }
      end
    end

    def handle_turbo_stream
      expand_group if expanding_group?
    end

    def set_default_sort
      @q.sorts = 'created_at desc' if @q.sorts.empty?
    end

    def expanding_group?
      params.key? :parent_id
    end

    def expand_group
      @group = Group.find(params[:parent_id])
      @level = params[:level].to_i
      @posinset = params[:posinset].to_i
      @setsize = params[:setsize].to_i
      @tabindex = params[:tabindex].to_i
      @children = @group.children
      render :group
    end

    def authorized_groups
      if @render_flat_list
        authorized_scope(Group, type: :relation)
      else
        authorized_scope(Group, type: :relation).without_descendants
      end
    end

    def current_page
      @current_page = t(:'general.default_sidebar.groups')
    end

    def page_title
      @title = t(:'general.default_sidebar.groups')
    end
  end
end

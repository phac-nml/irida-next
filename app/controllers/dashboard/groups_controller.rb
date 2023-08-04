# frozen_string_literal: true

module Dashboard
  # Dashboard groups controller
  class GroupsController < ApplicationController
    def index
      respond_to do |format|
        format.html do
          @groups = authorized_scope(Group, type: :relation).without_descendants.include_route.order(updated_at: :desc)
        end
        format.turbo_stream do
          @collapse = params[:collapse] == 'true'
          @group = Group.find(params[:parent_id])
          @depth = params[:depth].to_i
          @sub_groups = @group.children.first(10)
        end
      end
    end
  end
end

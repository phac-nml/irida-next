# frozen_string_literal: true

# Controller actions for Groups
class GroupsController < ApplicationController
  before_action :group

  def show
    respond_to do |format|
      format.html do
        render 'groups/show'
      end
    end
  end

  private

  def group
    @group ||= Group.find_by_full_path(request.params[:group_id] || request.params[:id]) # rubocop:disable Rails/DynamicFindBy
  end
end

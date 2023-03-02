# frozen_string_literal: true

# Controller actions for Groups
class GroupsController < ApplicationController
  layout :resolve_layout
  before_action :group, only: %i[edit show destroy update]

  def index
    @groups = Group.all
  end

  def show; end

  def new
    @group = Group.new
  end

  def edit; end

  def create
    respond_to do |format|
      @group = Group.new(group_params.merge(owner: current_user))
      if @group.save
        flash[:success] = t('.success')
        format.html { redirect_to group_path(@group.full_path) }
      else
        format.html { render :new, status: :unprocessable_entity, locals: { group: @group } }
      end
    end
  end

  def update
    respond_to do |format|
      if group.update(group_params)
        flash[:success] = t('.success')
        format.html { redirect_to group_path(group) }
      else
        format.html { render :edit, status: :unprocessable_entity, locals: { group: } }
      end
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_path
  end

  private

  def group
    @group ||= Group.find_by_full_path(request.params[:group_id] || request.params[:id]) # rubocop:disable Rails/DynamicFindBy
  end

  def group_params
    params.require(:group).permit(:name, :path, :description)
  end

  def resolve_layout
    case action_name
    when 'show', 'edit'
      'groups'
    else
      'application'
    end
  end
end

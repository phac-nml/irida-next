# frozen_string_literal: true

# Controller actions for Groups
class GroupsController < ApplicationController
  layout :resolve_layout
  before_action :group, only: %i[edit show destroy update]

  def index
    @groups = Group.all
  end

  def show
    # No necessary code here
  end

  def new
    @group = Group.find(params[:parent_id]) if params[:parent_id]
    @new_group = Group.new(parent_id: @group&.id)
    respond_to do |format|
      if @group
        format.html { render :new_subgroup }
      else
        format.html { render :new }
      end
    end
  end

  def edit
    # No necessary code here
  end

  def create
    respond_to do |format|
      @new_group = Group.new(group_params.merge(owner: current_user))
      if @new_group.save
        flash[:success] = t('.success')
        format.html { redirect_to group_path(@new_group.full_path) }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @group.update(group_params)
        flash[:success] = t('.success')
        format.html { redirect_to group_path(@group) }
      else
        format.html { render :edit, status: :unprocessable_entity }
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
    params.require(:group).permit(:name, :path, :description, :parent_id)
  end

  def resolve_layout
    case action_name
    when 'show', 'edit'
      'groups'
    when 'new'
      if params[:parent_id]
        'groups'
      else
        'application'
      end
    else
      'application'
    end
  end
end

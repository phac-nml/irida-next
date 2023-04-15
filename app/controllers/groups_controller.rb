# frozen_string_literal: true

# Controller actions for Groups
class GroupsController < ApplicationController
  layout :resolve_layout
  before_action :group, only: %i[edit show destroy update]
  before_action :context_crumbs, except: %i[index new create show]
  verify_authorized except: %i[index create]

  def index
    @groups = authorized_scope(Group, type: :relation)
  end

  def show
    authorize! @group
  end

  def new
    @group = Group.find(params[:parent_id]) if params[:parent_id]
    @new_group = Group.new(parent_id: @group&.id)
    authorize! @new_group
    respond_to do |format|
      format.html { render_new }
    end
  end

  def edit
    authorize! @group
  end

  def create
    skip_verify_authorized!
    @new_group = Groups::CreateService.new(current_user, group_params).execute
    if @new_group.persisted?
      flash[:success] = t('.success')
      redirect_to group_path(@new_group.full_path)
    else
      @group = @new_group.parent
      render_new status: :unprocessable_entity
    end
  end

  def update
    authorize! @group
    if Groups::UpdateService.new(@group, current_user, group_params).execute
      flash[:success] = t('.success')
      redirect_to group_path(@group)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! @group
    Groups::DestroyService.new(@group, current_user).execute
    if @group.destroyed?
      flash[:success] = t('.success', group_name: @group.name)
      redirect_to groups_path
    else
      flash[:error] = @group.errors.full_messages.first
      redirect_to group_path(@group)
    end
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
    when 'new', 'create'
      if @group
        'groups'
      else
        'application'
      end
    else
      'application'
    end
  end

  def render_new(options = {})
    if @group
      render :new_subgroup, options
    else
      render :new, options
    end
  end

  def context_crumbs
    @context_crumbs = [{
      name: I18n.t('groups.edit.title'),
      path: group_path
    }]
  end
end

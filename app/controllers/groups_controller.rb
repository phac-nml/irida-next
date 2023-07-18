# frozen_string_literal: true

# Controller actions for Groups
class GroupsController < Groups::ApplicationController
  layout :resolve_layout
  before_action :group, only: %i[edit show destroy update transfer]
  before_action :context_crumbs, except: %i[index new create show]
  before_action :authorized_namespaces, only: %i[edit new update create]

  def index
    @groups = authorized_scope(Group, type: :relation).order(updated_at: :desc)
  end

  def show
    authorize! @group, to: :read?
  end

  def new
    @group = Group.find(params[:parent_id]) if params[:parent_id]

    authorize! @group, to: :create_subgroup? if params[:parent_id]

    @new_group = Group.new(parent_id: @group&.id)
    respond_to do |format|
      format.html { render_new }
    end
  end

  def edit
    authorize! @group
  end

  def create
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
    if Groups::UpdateService.new(@group, current_user, group_params).execute
      flash[:success] = t('.success')
      redirect_to group_path(@group)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Groups::DestroyService.new(@group, current_user).execute
    if @group.deleted?
      flash[:success] = t('.success', group_name: @group.name)
      redirect_to groups_path
    else
      flash[:error] = @group.errors.full_messages.first
      redirect_to group_path(@group)
    end
  end

  def transfer
    new_namespace ||= Namespace.find_by(id: params.require(:new_namespace_id))
    if Groups::TransferService.new(@group, current_user).execute(new_namespace)
      flash[:success] = t('.success')
      redirect_to group_path(@group)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def group
    @group ||= Group.find_by_full_path(request.params[:group_id] || request.params[:id]) # rubocop:disable Rails/DynamicFindBy
  end

  def group_params
    params.require(:group).permit(:name, :path, :description, :parent_id)
  end

  def authorized_namespaces
    @authorized_namespaces = authorized_scope(Group, type: :relation, as: :manageable)
  end

  def resolve_layout
    case action_name
    when 'show', 'edit', 'update'
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

# frozen_string_literal: true

# Controller actions for Groups
class GroupsController < Groups::ApplicationController # rubocop:disable Metrics/ClassLength
  layout :resolve_layout
  before_action :group, only: %i[edit show destroy update transfer]
  before_action :context_crumbs, except: %i[index new create show]
  before_action :authorized_namespaces, except: %i[index show destroy]
  before_action :authorized_subgroups_and_projects, only: %i[show]

  def index
    redirect_to dashboard_groups_path
  end

  def show
    authorize! @group, to: :read?

    respond_to do |format|
      format.html do
        @groups = @subgroups_and_projects
      end
      format.turbo_stream do
        @group = Group.find(params[:parent_id])
        @collapsed = params[:collapse] == 'true'
        @sub_groups = @subgroups_and_projects
        @depth = params[:depth].to_i
      end
    end
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

  def update # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    respond_to do |format|
      @updated = Groups::UpdateService.new(@group, current_user, group_params).execute
      if @updated
        if group_params[:path]
          flash[:success] = t('.success', group_name: @group.name)
          format.turbo_stream { redirect_to edit_group_path(@group) }
        else
          format.turbo_stream do
            render status: :ok, locals: { type: 'success', message: t('.success', group_name: @group.name) }
          end
        end
      else
        format.turbo_stream do
          render status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    Groups::DestroyService.new(@group, current_user).execute
    if @group.deleted?
      flash[:success] = t('.success', group_name: @group.name)
      redirect_to dashboard_groups_path(format: :html)
    else
      flash[:error] = @group.errors.full_messages.first
      redirect_to group_path(@group)
    end
  end

  def transfer # rubocop:disable Metrics/AbcSize
    new_namespace ||= Namespace.find_by(id: params.require(:new_namespace_id))
    if Groups::TransferService.new(@group, current_user).execute(new_namespace)
      flash[:success] = t('.success')
      redirect_to group_path(@group)
    else
      @error = @group.errors.messages.values.flatten.first
      respond_to do |format|
        format.turbo_stream do
          render status: :unprocessable_entity, locals: { confirm_value: @group.path, error: @error }
        end
      end
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
    @authorized_namespaces = authorized_scope(Namespace,
                                              type: :relation, as: :manageable).where.not(type: Namespaces::UserNamespace.sti_name) # rubocop:disable Layout/LineLength
  end

  def authorized_subgroups_and_projects
    @subgroups_and_projects = Namespace.where(
      parent_id: params[:parent_id] || @group.id,
      type: [
        Namespaces::ProjectNamespace.sti_name, Group.sti_name
      ]
    ).include_route.order(type: :asc)
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

  protected

  def namespace
    @namespace = group
  end

  def namespace_path
    group_path(@group)
  end
end

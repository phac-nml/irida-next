# frozen_string_literal: true

# Controller actions for Groups
class GroupsController < Groups::ApplicationController # rubocop:disable Metrics/ClassLength
  layout :resolve_layout
  before_action :parent_group, only: %i[new]
  before_action :tab, :render_flat_list, only: %i[show]
  before_action :group, only: %i[activity edit show destroy update transfer]
  before_action :authorized_namespaces, except: %i[index show destroy]
  before_action :current_page

  def index
    redirect_to dashboard_groups_path
  end

  def show
    authorize! @group, to: :read?

    @q = namespaces_query
    @search_params = search_params

    set_default_sort
    @pagy, @namespaces = pagy(@q.result.include_route)
  end

  def new
    authorize! @group, to: :create_subgroup? if params[:parent_id]

    @new_group = Group.new(parent_id: @group&.id)
    respond_to do |format|
      format.html { render_new }
    end
  end

  def edit
    authorize! @group
    @authorized_namespaces -= [@group]
    @subgroups_count = @group.self_and_descendants_of_type([Group.sti_name]).size - 1
    @projects_count = @group.self_and_descendants_of_type([Namespaces::ProjectNamespace.sti_name]).size
    @samples_count = @group.samples_count
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

  def activity
    authorize! @group

    group_activities = @group.retrieve_group_activity.order(created_at: :desc)

    @pagy, raw_activities = pagy(group_activities, limit: 10)

    @activities = @group.human_readable_activity(raw_activities)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def destroy
    Groups::DestroyService.new(@group, current_user).execute
    if @group.deleted?
      flash[:success] = t('.success', group_name: @group.name)
      redirect_to dashboard_groups_path(format: :html)
    else
      flash[:error] = error_message(@group)
      redirect_to group_path(@group)
    end
  end

  def transfer # rubocop:disable Metrics/AbcSize
    new_namespace ||= Namespace.find_by(id: params.require(:new_namespace_id))
    respond_to do |format|
      if Groups::TransferService.new(@group, current_user).execute(new_namespace)
        flash[:success] = t('.success')
        format.turbo_stream { redirect_to edit_group_path(@group) }
      else
        @error = @group.errors.messages.values.flatten.first
        format.turbo_stream do
          render status: :unprocessable_entity, locals: { confirm_value: @group.path, error: @error }
        end
      end
    end
  end

  private

  def set_default_sort
    @q.sorts = 'created_at desc' if @q.sorts.empty?
  end

  def render_flat_list
    @render_flat_list = params.dig(:q, :name_or_puid_cont).present?
  end

  def parent_group
    @group = Group.find(params[:parent_id]) if params[:parent_id]
  end

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

  def namespaces_query
    if @tab == 'shared_namespaces'
      if @render_flat_list
        shared_namespaces_descendants.ransack(params[:q])
      else
        @group.shared_namespaces.ransack(params[:q])
      end

    elsif @render_flat_list
      namespace_descendants.ransack(params[:q])
    else
      namespace_children.ransack(params[:q])
    end
  end

  def namespace_children
    @group.children_of_type(
      [
        Namespaces::ProjectNamespace.sti_name, Group.sti_name
      ]
    )
  end

  def namespace_descendants
    @group.self_and_descendants_of_type([Namespaces::ProjectNamespace.sti_name,
                                         Group.sti_name])
  end

  def shared_namespaces_descendants
    @group.shared_namespaces.self_and_descendants.where(type: [Namespaces::ProjectNamespace.sti_name,
                                                               Group.sti_name])
  end

  def resolve_layout
    case action_name
    when 'show', 'edit', 'update', 'activity'
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
    @context_crumbs = @group.nil? ? [] : route_to_context_crumbs(@group.route)

    case action_name
    when 'new', 'create', 'show'
      @context_crumbs
    when 'activity'
      @context_crumbs += [{
        name: I18n.t('groups.activity.title'),
        path: group_activity_path
      }]
    else
      @context_crumbs += [{
        name: I18n.t('groups.edit.title'),
        path: group_canonical_path
      }]
    end
  end

  def current_page
    @current_page = case action_name
                    when 'new'
                      if @group
                        t(:'groups.sidebar.details')
                      else
                        t(:'general.default_sidebar.groups')
                      end
                    when 'show'
                      t(:'groups.sidebar.details')
                    when 'activity'
                      t(:'groups.sidebar.activity')
                    else
                      t(:'groups.sidebar.general')
                    end
  end

  def search_params
    search_params = {}
    search_params[:name_or_puid_cont] = params.dig(:q, :name_or_puid_cont)
    search_params
  end

  protected

  def namespace
    @namespace = group
  end

  def tab
    @tab = params[:tab]
  end
end

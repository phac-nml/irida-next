# frozen_string_literal: true

# Controller actions for Projects
class ProjectsController < Projects::ApplicationController # rubocop:disable Metrics/ClassLength
  include BreadcrumbNavigation
  layout :resolve_layout
  before_action :authorized_namespaces, only: %i[edit new update create transfer]
  before_action :current_page

  def index
    redirect_to dashboard_projects_path
  end

  def show
    authorize! @project, to: :read?
  end

  def new
    @project = Project.new
    @project.build_namespace(parent_id: params[:namespace_id] || current_user.namespace.id)

    authorize! @project
  end

  def edit
    authorize! @project
  end

  def create
    @project = Projects::CreateService.new(current_user, project_params).execute

    if @project.persisted?
      flash[:success] = t('.success', project_name: @project.name)
      redirect_to(
        project_samples_path(@project)
      )
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    respond_to do |format|
      @updated = Projects::UpdateService.new(@project, current_user, project_params).execute
      if @updated
        if project_params[:namespace_attributes][:path]
          flash[:success] = t('.success', project_name: @project.name)
          format.turbo_stream { redirect_to(project_edit_path(@project)) }
        else
          format.turbo_stream do
            render status: :ok, locals: { type: 'success', message: t('.success', project_name: @project.name) }
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
    authorize! @project
    @activities = PublicActivity::Activity.where(trackable_id: @project.namespace.id, trackable_type: 'Namespace')
  end

  def transfer # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    if Projects::TransferService.new(@project, current_user).execute(new_namespace)
      @project.namespace.create_activity key: 'namespaces_project_namespace.transfer', owner: current_user,
                                         parameters:
                                         {
                                           project_name: @project.name,
                                           old_namespace: @project.namespace.name,
                                           new_namespace: new_namespace.name
                                         }

      flash[:success] = t('.success', project_name: @project.name)
      respond_to do |format|
        format.turbo_stream { redirect_to project_path(@project) }
      end
    else
      @error = @project.errors.messages.values.flatten.first
      respond_to do |format|
        format.turbo_stream
      end
    end
  end

  def destroy
    Projects::DestroyService.new(@project, current_user).execute
    if @project.deleted?
      flash[:success] = t('.success', project_name: @project.name)
      redirect_to dashboard_projects_path(format: :html)
    else
      flash[:error] = @project.errors.full_messages.first
      redirect_to project_path(@project)
    end
  end

  private

  def project_params
    params.require(:project)
          .permit(project_params_attributes)
  end

  def namespace_attributes
    %i[
      name
      path
      description
      parent_id
    ]
  end

  def project_params_attributes
    [
      namespace_attributes:
    ]
  end

  def project
    return unless params[:project_id]

    path = [params[:namespace_id], params[:project_id]].join('/')
    @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
  end

  def authorized_namespaces
    @authorized_namespaces = authorized_scope(Namespace, type: :relation, as: :manageable)
    return unless @project

    @authorized_namespaces = @authorized_namespaces.where.not(id: @project.namespace.parent.id)
  end

  def new_namespace
    id = params.require(:new_namespace_id)
    Namespace.find_by(id:)
  end

  def resolve_layout
    case action_name
    when 'new', 'create'
      'application'
    else
      'projects'
    end
  end

  def context_crumbs
    @context_crumbs = @project.nil? || !@project.persisted? ? [] : route_to_context_crumbs(@project.namespace.route)

    case action_name
    when 'update', 'edit'
      @context_crumbs += [{
        name: I18n.t('projects.edit.title'),
        path: namespace_project_edit_path
      }]
    end
  end

  protected

  def namespace
    return unless params[:project_id]

    path = [params[:namespace_id], params[:project_id]].join('/')
    @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
    @namespace = @project.namespace

    authorized_namespaces
  end

  def current_page
    @current_page = case action_name
                    when 'show'
                      t(:'projects.sidebar.details')
                    when 'new'
                      t(:'general.default_sidebar.projects')
                    when 'history'
                      t(:'projects.sidebar.history')
                    else
                      t(:'projects.sidebar.general')
                    end
  end
end

# frozen_string_literal: true

# Controller actions for Projects
class ProjectsController < Projects::ApplicationController # rubocop:disable Metrics/ClassLength
  layout :resolve_layout
  before_action :project, only: %i[show edit update activity transfer destroy]
  before_action :context_crumbs, except: %i[index new create show]
  before_action :authorize_modify_project!, only: %i[edit]
  before_action :authorize_view_project!, only: %i[show]

  def index
    respond_to do |format|
      format.html do
        @has_projects = Project.joins(:namespace).exists?(namespace: { parent: current_user.namespace }) ||
                        Project.joins(:namespace)
                               .exists?(namespace: { parent: current_user.groups.self_and_descendant_ids })
      end
      format.turbo_stream do
        @pagy, @projects = pagy(authorized_scope(Project, type: :relation).order(updated_at: :desc))
      end
    end
  end

  def show
    # No necessary code here
  end

  def new
    @project = Project.new
    @project.build_namespace(parent_id: params[:namespace_id] || current_user.namespace.id)
  end

  def edit
    # No necessary code here
  end

  def create
    @project = Projects::CreateService.new(current_user, project_params).execute

    if @project.persisted?
      flash[:success] = t('.success', project_name: @project.name)
      redirect_to(
        project_path(@project)
      )
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if Projects::UpdateService.new(@project, current_user, project_params).execute
      flash[:success] = t('.success', project_name: @project.name)
      redirect_to(
        project_path(@project)
      )
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def activity
    # No necessary code here
  end

  def transfer
    new_namespace ||= Namespace.find_by(id: params.require(:new_namespace_id))
    if Projects::TransferService.new(@project, current_user).execute(new_namespace)
      redirect_to(
        project_path(@project),
        notice: t('.success', project_name: @project.name)
      )
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Projects::DestroyService.new(@project, current_user).execute
    if @project.destroyed?
      flash[:success] = t('.success', project_name: @project.name)
      redirect_to projects_path
    else
      flash[:error] = @project.errors.full_messages.first
      redirect_to namespace_project_path(@project)
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

  def resolve_layout
    case action_name
    when 'show', 'edit'
      'projects'
    else
      'application'
    end
  end

  def context_crumbs
    @context_crumbs = []

    case action_name
    when 'update', 'edit'
      @context_crumbs = [{
        name: I18n.t('projects.edit.title'),
        path: namespace_project_edit_path
      }]
    end
  end
end

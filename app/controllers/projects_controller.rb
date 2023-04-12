# frozen_string_literal: true

# Controller actions for Projects
class ProjectsController < ApplicationController
  layout :resolve_layout
  before_action :project, only: %i[show edit update activity transfer]
  before_action :context_crumbs, except: %i[index new create show]
  verify_authorized except: %i[index create]

  def index
    @projects = authorized_scope(Project, type: :relation)
  end

  def show
    authorize! @project
    # No necessary code here
  end

  def new
    @project = Project.new
    @project.build_namespace(parent_id: params[:namespace_id] || current_user.namespace.id)
  end

  def edit
    authorize! @project
    # No necessary code here
  end

  def create
    skip_verify_authorized!
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
    authorize! @project
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
    authorize! @project
    # No necessary code here
  end

  def transfer
    authorize! @project
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

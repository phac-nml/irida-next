# frozen_string_literal: true

# Controller actions for Projects
class ProjectsController < ApplicationController
  layout :resolve_layout
  before_action :project, only: %i[show edit update activity transfer]

  def index
    @projects = Project.all
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
      redirect_to(
        project_path(@project),
        notice: t('.success', project_name: @project.name)
      )
    else
      render 'new'
    end
  end

  def update
    if Projects::UpdateService.new(@project, current_user, project_params).execute
      redirect_to(
        project_path(@project),
        notice: t('.success', project_name: @project.name)
      )
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def activity
    # No necessary code here
  end

  def transfer
    new_namespace ||= Namespace.find(params.require(:new_namespace_id))
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
end

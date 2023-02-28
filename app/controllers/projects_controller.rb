# frozen_string_literal: true

# Controller actions for Projects
class ProjectsController < ApplicationController
  before_action :project, only: [:show]

  def show
    respond_to do |format|
      format.html do
        render 'show'
      end
    end
  end

  def new
    respond_to do |format|
      format.html do
        render 'new'
      end
    end
  end

  def create
    @project = Projects::CreateService.new(current_user, project_params).execute

    if @project.persisted?
      redirect_to(
        project_path(@project),
        notice: "Project #{@project.name} was successfully created."
      )
    else
      render 'new'
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
    return unless params[:project_id] || params[:id]

    path = [params[:namespace_id], params[:project_id] || params[:id]].join('/')
    @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
  end
end

# frozen_string_literal: true

module Projects
  # Controller actions for Samples
  class SamplesController < ApplicationController
    before_action :sample, only: %i[show edit update destroy]
    before_action :project
    before_action :context_crumbs
    verify_authorized

    layout 'projects'

    def index
      authorize! @project, to: :show?, default: Project
      @samples = authorized_scope(Sample, type: :relation, scope_options: { project_id: @project.id })
    end

    def show
      authorize! @sample unless sample.nil?
      return unless @sample.nil?

      render status: :unprocessable_entity, json: {
        message: t('.error')
      }
    end

    def new
      authorize! @project, to: :new?, default: Project
      @sample = Sample.new
    end

    def edit
      authorize! @project, to: :edit?, default: Project
    end

    def create
      authorize! @project, to: :create?, default: Project
      @sample = Samples::CreateService.new(current_user, @project, sample_params).execute

      if @sample.persisted?
        flash[:success] = t('.success')
        redirect_to namespace_project_sample_path(id: @sample.id)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      authorize! @sample
      respond_to do |format|
        if Samples::UpdateService.new(@sample, current_user, sample_params).execute
          flash[:success] = t('.success')
          format.html { redirect_to namespace_project_sample_path(id: @sample.id) }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize! @sample unless sample.nil?
      if @sample.nil?
        flash[:error] = t('.error')
      else
        Samples::DestroyService.new(@sample, current_user).execute
        if @sample.destroyed?
          flash[:success] = t('.success', sample_name: @sample.name)
        else
          flash[:error] = @sample.errors.full_messages.first
        end
      end
      redirect_to namespace_project_samples_path
    end

    private

    def sample
      @sample ||= Sample.find_by(id: params[:id], project_id: project.id)
    end

    def sample_params
      params.require(:sample).permit(:name, :description)
    end

    def project
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
    end

    def context_crumbs
      @context_crumbs = [{
        name: I18n.t('projects.samples.index.title'),
        path: namespace_project_samples_path
      }]
    end
  end
end

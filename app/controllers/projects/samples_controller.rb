# frozen_string_literal: true

module Projects
  # Controller actions for Samples
  class SamplesController < Projects::ApplicationController
    before_action :sample, only: %i[show edit update destroy]
    before_action :current_page

    def index
      authorize! @project, to: :sample_listing?
      respond_to do |format|
        format.html do
          @has_samples = Sample.exists?(project_id: @project.id)
        end
        format.turbo_stream do
          @pagy, @samples = pagy(Sample.where(project_id: @project.id))
        end
      end
    end

    def show
      authorize! @sample.project, to: :read_sample?
    end

    def new
      authorize! @project, to: :create_sample?

      @sample = Sample.new
    end

    def edit
      authorize! @sample.project, to: :update_sample?
    end

    def create
      @sample = ::Samples::CreateService.new(current_user, @project, sample_params).execute

      if @sample.persisted?
        flash[:success] = t('.success')
        redirect_to namespace_project_sample_path(id: @sample.id)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      respond_to do |format|
        if ::Samples::UpdateService.new(@sample, current_user, sample_params).execute
          flash[:success] = t('.success')
          format.html { redirect_to namespace_project_sample_path(id: @sample.id) }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      ::Samples::DestroyService.new(@sample, current_user).execute
      @pagy, @samples = pagy(Sample.where(project_id: @project.id))
      respond_to do |format|
        if @sample.deleted?
          format.turbo_stream do
            render status: :ok, locals: { type: 'success',
                                          message: t('.success', sample_name: @sample.name) }
          end
        else
          format.turbo_stream do
            render status: :unprocessable_entity,
                   locals: { type: 'alert', message: @sample.errors.full_messages.first }
          end
        end
      end
    end

    private

    def sample
      @sample = Sample.find_by(id: params[:id], project_id: project.id) || not_found
    end

    def sample_params
      params.require(:sample).permit(:name, :description)
    end

    def context_crumbs
      super
      @context_crumbs += [{
        name: I18n.t('projects.samples.index.title'),
        path: namespace_project_samples_path
      }]
    end

    def current_page
      @current_page = 'samples'
    end
  end
end

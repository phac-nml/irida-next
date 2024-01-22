# frozen_string_literal: true

module Projects
  # Controller actions for Samples
  class SamplesController < Projects::ApplicationController
    before_action :sample, only: %i[show edit update destroy]
    before_action :current_page

    def index
      authorize! @project, to: :sample_listing?

      @q = load_samples.ransack(params[:q])
      set_default_sort
      respond_to do |format|
        format.html do
          @has_samples = @q.result.count.positive?
        end
        format.turbo_stream do
          @pagy, @samples = pagy(@q.result)
        end
      end
    end

    def show
      authorize! @sample.project, to: :read_sample?
      @tab = params[:tab]
      @table_listing = if @tab == 'metadata'
                         @sample.metadata_with_provenance
                       else
                         @sample.attachments
                       end
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

    def destroy # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      ::Samples::DestroyService.new(@sample, current_user).execute
      @pagy, @samples = pagy(load_samples)
      @q = load_samples.ransack(params[:q])

      if @sample.deleted?
        respond_to do |format|
          format.html do
            flash[:success] = t('.success', sample_name: @sample.name, project_name: @project.namespace.human_name)
            redirect_to namespace_project_samples_path(format: :html)
          end
          format.turbo_stream do
            render status: :ok, locals: { type: 'success',
                                          message: t('.success', sample_name: @sample.name,
                                                                 project_name: @project.namespace.human_name) }
          end
        end
      else
        respond_to do |format|
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

    def set_default_sort
      @q.sorts = 'updated_at desc' if @q.sorts.empty?
    end
  end
end

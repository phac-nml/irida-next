# frozen_string_literal: true

module Projects
  # Controller actions for Samples
  class SamplesController < Projects::ApplicationController # rubocop:disable Metrics/ClassLength
    include Metadata
    include SampleActions

    before_action :sample, only: %i[show edit update view_history_version]
    before_action :current_page
    before_action :set_search_params, only: %i[index]
    before_action :set_metadata_fields, only: :index

    def index
      authorize! @project, to: :sample_listing?

      @q = load_samples.ransack(params[:q])
      set_default_sort
      @pagy, @samples = pagy_with_metadata_sort(@q.result)
      @has_samples = load_samples.count.positive?
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def show
      authorize! @sample.project, to: :read_sample?
      @tab = params[:tab]
      if @tab == 'metadata'
        @sample_metadata = @sample.metadata_with_provenance
      elsif @tab == 'history'
        @log_data = @sample.log_data_without_changes
      else
        @sample_attachments = @sample.attachments
      end
    end

    def view_history_version
      authorize! @sample.project, to: :view_history?

      @log_data = @sample.log_data_with_changes(params[:version])
      respond_to do |format|
        format.turbo_stream do
          render status: :ok
        end
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

    def select
      authorize! @project, to: :sample_listing?
      @samples = []

      respond_to do |format|
        format.turbo_stream do
          if params[:select].present?
            @q = load_samples.ransack(params[:q])
            @samples = @q.result.select(:id)
          end
        end
      end
    end

    private

    def sample
      @sample = Sample.find_by(id: params[:id] || params[:sample_id], project_id: project.id) || not_found
    end

    def sample_params
      params.require(:sample).permit(:name, :description)
    end

    def context_crumbs
      super
      @context_crumbs +=
        [{
          name: I18n.t('projects.samples.index.title'),
          path: namespace_project_samples_path
        }]
      return unless action_name == 'show' && !@sample.nil?

      @context_crumbs +=
        [{
          name: @sample.puid,
          path: namespace_project_sample_path(id: @sample.id)
        }]
    end

    def current_page
      @current_page = t(:'projects.sidebar.samples')
    end

    def set_default_sort
      # remove metadata sort if metadata not visible
      if !@q.sorts.empty? && @q.sorts[0].name.start_with?('metadata_') && params[:q][:metadata].to_i != 1
        @q.sorts.slice!(0)
      end

      @q.sorts = 'updated_at desc' if @q.sorts.empty?
    end

    def set_search_params
      @search_params = params[:q].nil? ? {} : params[:q].to_unsafe_h
    end

    def set_metadata_fields
      fields_for_namespace(
        namespace: @project.namespace,
        show_fields: params[:q] && params[:q][:metadata].to_i == 1
      )
    end
  end
end

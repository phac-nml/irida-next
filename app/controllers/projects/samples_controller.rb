# frozen_string_literal: true

module Projects
  # Controller actions for Samples
  class SamplesController < Projects::ApplicationController # rubocop:disable Metrics/ClassLength
    include Metadata
    include SampleActions
    include Storable

    before_action :sample, only: %i[show edit update view_history_version]
    before_action :current_page
    before_action :process_samples, only: %i[index search]
    include Sortable

    def index
      @pagy, @samples = pagy_with_metadata_sort(@q.result)
      @has_samples = load_samples.count.positive?
    end

    def search
      redirect_to namespace_project_samples_path
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
            @q = load_samples.ransack(search_params)
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

    def layout_fixed
      super
      return unless action_name == 'index'

      @fixed = false
    end

    def current_page
      @current_page = t(:'projects.sidebar.samples')
    end

    def set_metadata_fields
      fields_for_namespace(
        namespace: @project.namespace,
        show_fields: @search_params && @search_params[:metadata].to_i == 1
      )
    end

    def search_key
      :"#{controller_name}_#{@project.id}_search_params"
    end

    def process_samples
      authorize! @project, to: :sample_listing?

      @search_params = search_params

      set_metadata_fields
      @q = load_samples.ransack(@search_params)
    end

    def search_params
      updated_params = update_store(search_key, params[:q].present? ? params[:q].to_unsafe_h : {})

      if updated_params[:metadata].to_i.zero? && updated_params[:s].present? && updated_params[:s].match?(/metadata_/)
        updated_params[:s] = default_sort
        update_store(search_key, updated_params)
      end
      updated_params
    end
  end
end

# frozen_string_literal: true

module Projects
  # Controller actions for Samples
  class SamplesController < Projects::ApplicationController # rubocop:disable Metrics/ClassLength
    include Metadata
    include ListActions
    include Storable

    before_action :sample, only: %i[show edit update view_history_version]
    before_action :current_page
    before_action :query, only: %i[index search select]
    before_action :current_metadata_template, only: %i[index]
    before_action :index_view_authorizations, only: %i[index]
    before_action :show_view_authorizations, only: %i[show]

    def index
      @timestamp = DateTime.current
      @pagy, @samples = @query.results(limit: params[:limit] || 20, page: params[:page] || 1)
      @samples = @samples.includes(project: { namespace: :parent })
      @has_samples = @project.samples.size.positive?
    end

    def search
      respond_to do |format|
        format.turbo_stream do
          if @query.valid?
            render status: :ok
          else
            render status: :unprocessable_entity
          end
        end
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
      @sample_ids = []

      respond_to do |format|
        format.turbo_stream do
          if params[:select].present?
            @sample_ids = @query.results.where(updated_at: ..params[:timestamp].to_datetime).select(:id).pluck(:id)
          end
        end
      end
    end

    private

    def index_view_authorizations
      @allowed_to = {
        submit_workflow: allowed_to?(:submit_workflow?, @project),
        clone_sample: allowed_to?(:clone_sample?, @project),
        transfer_sample: allowed_to?(:transfer_sample?, @project),
        export_data: allowed_to?(:export_data?, @project),
        update_sample_metadata: allowed_to?(:update_sample_metadata?, @project.namespace),
        create_sample: allowed_to?(:create_sample?, @project),
        destroy_sample: allowed_to?(:destroy_sample?, @project),
        update_sample: allowed_to?(:update_sample?, @project),
        import_samples_and_metadata: allowed_to?(:import_samples_and_metadata?, @project.namespace)
      }
    end

    def show_view_authorizations
      @allowed_to = {
        destroy_sample: allowed_to?(:destroy_sample?, @project),
        destroy_attachment: allowed_to?(:destroy_attachment?, @sample),
        update_sample: allowed_to?(:update_sample?, @project)
      }
    end

    def sample
      @sample = Sample.find_by(id: params[:id] || params[:sample_id], project_id: project.id) || not_found
    end

    def sample_params
      params.expect(sample: %i[name description])
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

    def metadata_fields(template)
      fields_for_namespace_or_template(
        namespace: @project.namespace,
        template: template
      )
    end

    def search_key
      :"#{controller_name}_#{@project.id}_search_params"
    end

    def query
      authorize! @project, to: :sample_listing?

      @search_params = search_params

      metadata_fields(@search_params['metadata_template'])

      advanced_search_fields(@project.namespace)

      @query = Sample::Query.new(@search_params.except('metadata_template').merge({ project_ids: [@project.id] }))
    end

    def search_params
      updated_params = update_store(search_key,
                                    params[:q].present? ? params[:q].to_unsafe_h : {}).with_indifferent_access
      updated_params.slice!('name_or_puid_cont', 'name_or_puid_in', 'groups_attributes',
                            'metadata_template', 'sort')

      if !updated_params.key?(:sort) ||
         (updated_params[:metadata_template] == 'none' && updated_params[:sort]&.match?(/metadata_/))
        updated_params[:sort] = 'updated_at desc'
        update_store(search_key, updated_params)
      end
      updated_params
    end
  end
end

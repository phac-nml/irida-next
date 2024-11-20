# frozen_string_literal: true

module Projects
  # Controller actions for Samples
  class SamplesController < Projects::ApplicationController # rubocop:disable Metrics/ClassLength
    include Metadata
    include ListActions
    include Storable

    before_action :sample, only: %i[show edit update view_history_version]
    before_action :current_page
    before_action :process_samples, only: %i[index search select]

    def index
      @timestamp = DateTime.current
      # @pagy, @samples = pagy_with_metadata_sort(@q.result)
      collection = Sample.pagy_search(@search_params.fetch(:name_or_puid_cont, '*'),
                                      fields: [{ name: :text_middle }, { puid: :text_middle }],
                                      misspellings: false,
                                      where: { project_id: project.id }.merge((
                                        if @search_params.fetch(:name_or_puid_in,
                                                                nil).present?
                                          { _or: [{ name: @search_params[:name_or_puid_in] },
                                                  { puid: @search_params[:name_or_puid_in] }] }
                                        else
                                          {}
                                        end
                                      )),
                                      order: sort,
                                      includes: [:project])
      @pagy, @samples = pagy_searchkick(collection, limit: params[:limit] || 20)
      @has_samples = @project.samples.size.positive?
    end

    def search
      redirect_to namespace_project_samples_path(request.request_parameters.slice(:limit, :page))
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
      @selected_sample_ids = []

      respond_to do |format|
        format.turbo_stream do
          if params[:select].present?
            @selected_sample_ids = Sample.search(@search_params.fetch(:name_or_puid_cont, '*'),
                                                 fields: [{ name: :text_middle }, { puid: :text_middle }],
                                                 misspellings: false,
                                                 where: { project_id: project.id,
                                                          updated_at: { lte: params[:timestamp].to_datetime } }.merge((
                                                   if @search_params.fetch(:name_or_puid_in,
                                                                           nil).present?
                                                     { _or: [{ name: @search_params[:name_or_puid_in] },
                                                             { puid: @search_params[:name_or_puid_in] }] }
                                                   else
                                                     {}
                                                   end
                                                 ))).pluck(:id)
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
      # query_parser = Irida::SearchSyntax::Ransack.new(text: :name_or_puid_cont, metadata_fields: @fields)
      # @parsed_params = query_parser.parse(@search_params.fetch(:name_or_puid_cont, nil))
      # @q = load_samples.ransack(@search_params.except(:name_or_puid_cont).merge(@parsed_params))
    end

    def search_params
      updated_params = update_store(search_key, params[:q].present? ? params[:q].to_unsafe_h : {})

      if !updated_params.key?(:s) || (updated_params.fetch(:metadata,
                                                           0).to_i.zero? && updated_params[:s].match?(/metadata_/))
        updated_params[:s] = 'updated_at desc'
        update_store(search_key, updated_params)
      end
      updated_params
    end

    def sort
      sort = @search_params[:s]
      key, direction = sort.split
      key = key.gsub('metadata_', 'metadata.') if key.match?(/metadata_/)
      { "#{key}": direction }
    end
  end
end

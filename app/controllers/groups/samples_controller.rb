# frozen_string_literal: true

module Groups
  # Controller actions for Samples within a Group
  class SamplesController < Groups::ApplicationController
    include Metadata
    include Storable

    before_action :group, :current_page
    before_action :process_samples, only: %i[index search select]

    def index
      @timestamp = DateTime.current
      # @pagy, @samples = pagy_with_metadata_sort(@q.result)
      collection = Sample.pagy_search(@search_params.fetch(:name_or_puid_cont, '*'),
                                      fields: [{ name: :text_middle }, { puid: :text_middle }],
                                      misspellings: false,
                                      where: { project_id: authorized_projects.pluck(:id) }.merge((
                                        if @search_params.fetch(:name_or_puid_in,
                                                                nil).present?
                                          { _or: [{ name: @search_params[:name_or_puid_in] },
                                                  { puid: @search_params[:name_or_puid_in] }] }
                                        else
                                          {}
                                        end
                                      )),
                                      order: sort,
                                      includes: [project: { namespace: [{ parent: :route }, :route] }])
      @pagy, @samples = pagy_searchkick(collection, limit: params[:limit] || 20)
      @has_samples = true
    end

    def search
      redirect_to group_samples_path(request.request_parameters.slice(:limit, :page))
    end

    def select
      authorize! @group, to: :sample_listing?
      @selected_sample_ids = []

      respond_to do |format|
        format.turbo_stream do
          if params[:select].present?
            @selected_sample_ids = Sample.search(@search_params.fetch(:name_or_puid_cont, '*'),
                                                 fields: [{ name: :text_middle }, { puid: :text_middle }],
                                                 misspellings: false,
                                                 where: { project_id: authorized_projects.pluck(:id),
                                                          updated_at: { lte: params[:timestamp].to_datetime } }.merge((
                                                   if @search_params.fetch(:name_or_puid_in,
                                                                           nil).present?
                                                     { _or: [{ name: @search_params[:name_or_puid_in] },
                                                             { puid: @search_params[:name_or_puid_in] }] }
                                                   else
                                                     {}
                                                   end
                                                 ))).select(:id).pluck(:id)
          end
        end
      end
    end

    private

    def group
      @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
    end

    def authorized_projects
      authorized_scope(Project, type: :relation, as: :group_projects, scope_options: { group: @group })
    end

    def authorized_samples
      authorized_scope(Sample, type: :relation, as: :namespace_samples,
                               scope_options: { namespace: @group }).includes(project: { namespace: [{ parent: :route },
                                                                                                     :route] })
    end

    def layout_fixed
      super
      return unless action_name == 'index'

      @fixed = false
    end

    def context_crumbs
      super
      case action_name
      when 'index'
        @context_crumbs += [{
          name: I18n.t('groups.samples.index.title'),
          path: group_samples_path
        }]
      end
    end

    def current_page
      @current_page = t(:'groups.sidebar.samples')
    end

    def set_metadata_fields
      fields_for_namespace(namespace: @group, show_fields: @search_params && @search_params[:metadata].to_i == 1)
    end

    def process_samples
      authorize! @group, to: :sample_listing?
      @search_params = search_params
      set_metadata_fields
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

    def search_key
      :"#{controller_name}_#{group.id}_search_params"
    end

    def sort
      sort = @search_params[:s]
      key, direction = sort.split
      key = key.gsub('metadata_', 'metadata.') if key.match?(/metadata_/)
      { "#{key}": direction }
    end
  end
end

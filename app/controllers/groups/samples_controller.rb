# frozen_string_literal: true

module Groups
  # Controller actions for Samples within a Group
  class SamplesController < Groups::ApplicationController
    include Metadata
    include Storable

    before_action :group, :current_page
    before_action :process_samples, only: %i[index search select]
    include Sortable

    def index
      @timestamp = DateTime.current
      @pagy, @samples = pagy_with_metadata_sort(@q.result)
      @has_samples = authorized_samples.count.positive?
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
            @selected_sample_ids = @q.result.where(updated_at: ..params[:timestamp].to_datetime).select(:id).pluck(:id)
          end
        end
      end
    end

    private

    def group
      @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
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
      query_parser = Irida::SearchSyntax::Ransack.new(text: :name_or_puid_cont,
                                                      # params: { project: 'project_namespace_puid' },
                                                      metadata_fields: @fields)
      parsed_params = query_parser.parse(@search_params.fetch(:name_or_puid_cont, nil))
      @q = authorized_samples.ransack(@search_params.except(:name_or_puid_cont).merge(parsed_params))
    end

    def search_params
      updated_params = update_store(search_key, params[:q].present? ? params[:q].to_unsafe_h : {})

      if updated_params[:metadata].to_i.zero? && updated_params[:s].present? && updated_params[:s].match?(/metadata_/)
        updated_params[:s] = default_sort
        update_store(search_key, updated_params)
      end
      query_parser = Irida::SearchSyntax::Ransack.new(text: :name_or_puid_cont,
                                                      # params: { project: 'project_namespace_puid' },
                                                      metadata_fields: @fields)
      parsed_params = query_parser.parse(@search_params.fetch(:name_or_puid_cont, nil))
      updated_params.except(:name_or_puid_cont).merge(parsed_params)
    end

    def search_key
      :"#{controller_name}_#{group.id}_search_params"
    end
  end
end

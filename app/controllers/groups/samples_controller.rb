# frozen_string_literal: true

module Groups
  # Controller actions for Samples within a Group
  class SamplesController < Groups::ApplicationController # rubocop:disable Metrics/ClassLength
    include Metadata
    include Storable
    include ListActions

    before_action :group, :current_page
    before_action :query, only: %i[index search select]
    before_action :current_metadata_template, only: %i[index]
    before_action :index_view_authorizations, only: %i[index]
    before_action :page_title

    def index
      @timestamp = DateTime.current
      @pagy, @samples = @query.results(limit: params[:limit] || 20, page: params[:page] || 1)
      @samples = @samples.includes(project: { namespace: :parent })
      @has_samples = @group.has_samples?
      @results_message = results_message
    end

    def search
      respond_to do |format|
        format.turbo_stream do
          if @query.valid?
            render status: :ok
          else
            render status: :unprocessable_content
          end
        end
      end
    end

    def select
      authorize! @group, to: :sample_listing?
      @sample_ids = []

      return if params[:select].blank?

      @sample_ids = @query.results.reorder(nil).where(updated_at: ..params[:timestamp].to_datetime).pluck(:id)
    end

    private

    def index_view_authorizations
      @allowed_to = {
        submit_workflow: allowed_to?(:submit_workflow?, @group),
        export_data: allowed_to?(:export_data?, @group),
        update_sample_metadata: allowed_to?(:update_sample_metadata?, @group),
        import_samples_and_metadata: allowed_to?(:import_samples_and_metadata?, @group),
        clone_sample: allowed_to?(:clone_sample?, @group),
        transfer_sample: allowed_to?(:transfer_sample?, @group),
        destroy_sample: allowed_to?(:destroy_sample?, @group)
      }

      @render_sample_actions = @allowed_to.slice(
        :export_data, :update_sample_metadata, :import_samples_and_metadata
      ).value?(true)
    end

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

    def metadata_fields(template)
      fields_for_namespace_or_template(namespace: @group, template:)
    end

    def query
      authorize! @group, to: :sample_listing?

      @search_params = search_params
      metadata_fields(@search_params['metadata_template'])
      advanced_search_fields(@group)

      @group_project_ids = authorized_scope(Project, type: :relation, as: :group_projects,
                                                     scope_options: { group: @group }).pluck(:id)

      @query = Sample::Query.new(@search_params.except('metadata_template').merge({ project_ids: @group_project_ids }))
    end

    def results_message
      @results_message =
        if @query.advanced_query?
          results_message_for_advanced_search
        elsif @query.name_or_puid_cont
          results_message_for_quick_search
        end
    end

    def results_message_for_advanced_search
      if @pagy&.count&.zero?
        I18n.t(:'components.search.advanced.results_message.zero')
      elsif @pagy&.one?
        I18n.t(:'components.search.advanced.results_message.singular')
      else
        I18n.t(:'components.search.advanced.results_message.plural', total_count: @pagy&.count)
      end
    end

    def results_message_for_quick_search
      if @pagy&.count&.zero?
        I18n.t(:'components.search.results_message.zero', search_term: @query.name_or_puid_cont)
      elsif @pagy&.one?
        I18n.t(:'components.search.results_message.singular', search_term: @query.name_or_puid_cont)
      else
        I18n.t(:'components.search.results_message.plural', total_count: @pagy&.count,
                                                            search_term: @query.name_or_puid_cont)
      end
    end

    def search_params
      updated_params = update_store(search_key, params[:q].present? ? params[:q].to_unsafe_h : {})
      updated_params.slice!('name_or_puid_cont', 'name_or_puid_in', 'groups_attributes', 'metadata_template', 'sort')

      if !updated_params.key?('sort') ||
         (updated_params[:metadata_template] == 'none' && updated_params['sort']&.match?(/metadata_/))
        updated_params['sort'] = 'updated_at desc'
        update_store(search_key, updated_params)
      end
      updated_params
    end

    def search_key
      :"#{controller_name}_#{group.id}_search_params"
    end

    def page_title
      @title = [t(:'activerecord.models.sample.other'), @group.full_name].join(' · ')
    end
  end
end

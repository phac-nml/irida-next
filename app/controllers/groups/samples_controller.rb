# frozen_string_literal: true

module Groups
  # Controller actions for Samples within a Group
  class SamplesController < Groups::ApplicationController
    include Metadata

    before_action :group, :current_page
    before_action :set_search_params, only: %i[index]
    before_action :set_metadata_fields, only: %i[index]

    def index
      authorize! @group, to: :sample_listing?

      @q = authorized_samples.ransack(params[:q])
      set_default_sort
      @pagy, @samples = pagy_with_metadata_sort(@q.result)
      @has_samples = authorized_samples.count.positive?
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def select
      authorize! @group, to: :sample_listing?
      @selected_sample_ids = []

      respond_to do |format|
        format.turbo_stream do
          if params[:select].present?
            @q = authorized_samples.ransack(params[:q])
            @selected_sample_ids = @q.result.select(:id).pluck(:id)
          end
        end
      end
    end

    private

    def group
      @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
    end

    def authorized_samples
      authorized_scope(Sample, type: :relation, as: :group_samples,
                               scope_options: { group: @group }).includes(project: { namespace: [{ parent: :route },
                                                                                                 :route] })
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
      @current_page = t(:'groups.sidebar.samples').downcase
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
      fields_for_namespace(namespace: @group, show_fields: params[:q] && params[:q][:metadata].to_i == 1)
    end
  end
end

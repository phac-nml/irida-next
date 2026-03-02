# frozen_string_literal: true

module GlobalSearch
  # Component for the global search dialog
  class DialogComponent < Component
    attr_reader :user

    def initialize(user:, params: {})
      @user = user
      @search_params = GlobalSearch::Params.new(params)
      @raw_params = params
    end

    def selected_types = @search_params.types
    def selected_match_sources = @search_params.match_sources
    def selected_sort = @search_params.sort
    def selected_workflow_state = @search_params.filters[:workflow_state]
    def selected_query = @search_params.query.presence
    def selected_created_from = @raw_params[:created_from]
    def selected_created_to = @raw_params[:created_to]

    def places
      [
        { label: t('general.default_sidebar.projects'), url: dashboard_projects_path },
        { label: t('general.default_sidebar.groups'), url: groups_path },
        { label: t('general.default_sidebar.workflows'), url: workflow_executions_path },
        { label: t('general.default_sidebar.data_exports'), url: data_exports_path }
      ]
    end

    def frequent_projects
      frequent_items[:projects]
    end

    def frequent_groups
      frequent_items[:groups]
    end

    private

    def frequent_items
      @frequent_items ||= GlobalSearch::FrequentItems.new(user, limit: 5).call
    end
  end
end

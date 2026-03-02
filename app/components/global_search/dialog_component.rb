# frozen_string_literal: true

module GlobalSearch
  # Component for the global search dialog
  class DialogComponent < Component
    attr_reader :user

    def initialize(user:)
      @user = user
    end

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

# frozen_string_literal: true

module Groups
  # Controller actions for group history
  class HistoryController < Groups::ApplicationController
    include HistoryActions

    before_action :current_page

    private

    # The model the log data is attached to
    def set_model
      @model = group
    end

    # The record to authorize the user against
    def set_authorization_object
      @authorize_object = group
    end

    def group
      @group ||= Group.find_by_full_path(request.params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      @group
    end

    protected

    def context_crumbs
      @context_crumbs = @group.nil? ? [] : route_to_context_crumbs(@group.route)
      case action_name
      when 'index', 'new'
        @context_crumbs += [{
          name: I18n.t('groups.history.index.title'),
          path: group_history_path
        }]
      end
    end

    def current_page
      @current_page = t(:'groups.sidebar.history').downcase
    end
  end
end

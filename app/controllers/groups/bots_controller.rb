# frozen_string_literal: true

module Groups
  # Controller actions for Bots
  class BotsController < Groups::ApplicationController
    include BreadcrumbNavigation
    include BotActions

    respond_to :turbo_stream
    before_action :current_page
    before_action :page_title

    private

    def bot_params
      params.expect(bot: [:id, :token_name, :access_level, :expires_at, { scopes: [] }])
    end

    protected

    def namespace
      @group ||= Group.find_by_full_path(request.params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      @namespace = @group
    end

    def context_crumbs
      super
      case action_name
      when 'index'
        @context_crumbs += [{
          name: t('groups.bots.index.title'),
          path: group_bots_path
        }]
      end
    end

    def current_page
      @current_page = t(:'groups.sidebar.bot_accounts')
    end

    def bot_type
      @bot_type = User.user_types[:group_bot]
    end

    def redirect_path
      group_bots_path
    end

    def page_title
      @title = [t(:'groups.sidebar.bot_accounts'), t(:'groups.edit.title'), @group.full_name].join(' · ')
    end
  end
end

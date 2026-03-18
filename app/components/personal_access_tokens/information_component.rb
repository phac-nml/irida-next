# frozen_string_literal: true

module PersonalAccessTokens
  # Component for rendering an personal access tokens information
  class InformationComponent < Component
    attr_accessor :current_user, :active_count, :expired_count, :revoked_count, :expiring_count

    def initialize(current_user:)
      @current_user = current_user
      @active_count = current_user.personal_access_tokens.active.count
      @expired_count = current_user.personal_access_tokens.expired.count
      @expiring_count = current_user.personal_access_tokens.expiring_in_two_weeks.count
      @revoked_count = current_user.personal_access_tokens.revoked.count
    end

    def statistic_button(type, count)
      button_to t("personal_access_tokens.information_component.view_#{type}"),
                list_profile_personal_access_tokens_path,
                data: { 'turbo-stream': true },
                params: { type: type },
                method: :get,
                type: :button,
                disabled: count.zero?,
                class:
                  'button button-default'
    end
  end
end

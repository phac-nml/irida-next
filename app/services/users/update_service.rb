# frozen_string_literal: true

module Users
  # Service used to update a user
  class UpdateService < BaseService
    attr_accessor :user_to_update

    def initialize(user, user_to_update, params = {})
      super(user, params)
      @user_to_update = user_to_update
    end

    def execute
      authorize! @current_user, to: :update?
      @user_to_update.update(params)
    end
  end
end

# frozen_string_literal: true

module Users
  # Service used to update a user
  class UpdateService < BaseService
    attr_accessor :user, :user_to_update, :initial_setup

    def initialize(user, resource, initial_setup = false, params = {})
      super(user, params)
      @user_to_update = resource
      @initial_setup = initial_setup
    end

    def execute
      authorize! @current_user, to: :update? unless initial_setup
      @user_to_update.update(params)
    end
  end
end

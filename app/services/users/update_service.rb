# frozen_string_literal: true

module Users
  # Service used to update a user
  class UpdateService < BaseService
    attr_accessor :user, :user_to_update, :initial_setup

    def initialize(user_to_update, params = {})
      super(current_user, params)
      @user_to_update = user_to_update
      @initial_setup = params[:initial_setup]
    end

    def execute
      authorize! @current_user, to: :update? unless initial_setup
      @user_to_update.update(params.except(:initial_setup))
    end
  end
end

# frozen_string_literal: true

module Admin
  # Initial setup controller
  class InitialSetupController < ApplicationController
    include CheckInitialSetup
    layout 'devise'

    skip_before_action :authenticate_user!
    before_action :user, only: %i[update]
    before_action :check_initial_setup

    def update
      @user = User.find(params[:id])
      updated = Users::UpdateService.new(@user, { admin: true, initial_setup: params[:initial_setup] }).execute

      if updated
        redirect_to new_user_session_path, notice: 'Initial account configured! Please sign in.'
      else
        redirect_to new_user_registration_path
      end
    end

    private

    def check_initial_setup
      if in_initial_setup_state?
        @user = User.admins.last
        return
      end

      # redirect to root_path to avoid potential redirect loop on sessions_controller
      redirect_to root_path, 'Initial setup complete!'
    end

    def user
      @user = User.find(params[:id]) || not_found
    end
  end
end

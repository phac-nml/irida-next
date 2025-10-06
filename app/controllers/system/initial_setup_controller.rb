# frozen_string_literal: true

module System
  # Initial setup controller
  class InitialSetupController < ApplicationController
    include CheckInitialSetup
    layout 'devise'

    skip_before_action :authenticate_user!
    before_action :user, only: %i[update]
    before_action :check_initial_setup

    def update
      updated = Users::UpdateService.new(current_user, @user,
                                         { system: true, initial_setup: true }).execute

      return unless updated

      redirect_to new_user_session_path, notice: I18n.t('system.initial_setup.update.success')
    end

    private

    def check_initial_setup
      if in_initial_setup_state?
        @user = User.last
        return
      end

      # redirect to root_path to avoid potential redirect loop on sessions_controller
      redirect_to new_user_registration_path
    end

    def user
      @user ||= User.find_by(id: params[:id])
    end
  end
end

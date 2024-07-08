# frozen_string_literal: true

# Purpose: To handle the user's account settings
module Profiles
  # Controller for the user account page
  class AccountsController < Profiles::ApplicationController
    # Get account page
    def show
      authorize! @user, to: :read?
    end

    def destroy
      authorize! @user
      @user.destroy
      redirect_to new_user_session_url
    end

    def current_page
      @current_page = t(:'profiles.sidebar.account')
    end
  end
end

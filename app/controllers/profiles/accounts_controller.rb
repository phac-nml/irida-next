# frozen_string_literal: true

# Purpose: To handle the user's account settings
module Profiles
  # Controller for the user account page
  class AccountsController < Profiles::ApplicationController
    layout 'profiles'

    # Get account page
    def show
      # No necessary code here
    end

    def destroy
      @user.destroy
      redirect_to new_user_session_url
    end
  end
end

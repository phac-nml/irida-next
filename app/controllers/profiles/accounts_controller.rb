# frozen_string_literal: true

# Purpose: To handle the user's account settings
module Profiles
  # Controller for the user account page
  class AccountsController < Profiles::ApplicationController
    before_action :page_title

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

    def page_title
      @title = "#{t(:'profiles.sidebar.account')} · #{current_user.namespace.full_path}"
    end
  end
end

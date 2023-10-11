# frozen_string_literal: true

# Purpose: To handle the user's site preferences
module Profiles
  # Controller for the user personal preferences page
  class PreferencesController < Profiles::ApplicationController
    before_action :current_page

    def show
      authorize! @user, to: :read?
    end

    def current_page
      @current_page = 'preferences'
    end
  end
end

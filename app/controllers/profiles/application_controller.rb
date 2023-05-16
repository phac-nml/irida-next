# frozen_string_literal: true

module Profiles
  # Base Controller for the users profile
  class ApplicationController < ApplicationController
    before_action :set_user
    before_action :authorize_user_profile_access!

    layout 'profiles'

    private

    def set_user
      @user = current_user
    end
  end
end

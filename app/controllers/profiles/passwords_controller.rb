# frozen_string_literal: true

# Purpose: To handle the user's password settings
module Profiles
  # Controller for the user password page
  class PasswordsController < ApplicationController
    layout 'profiles'

    before_action :set_user

    # Get password page
    def edit
      # No necessary code here
    end

    # Update the user's password
    def update
      respond_to do |format|
        if @user.update_password_with_password(update_password_params)
          # Sign in the user bypassing validation in case their password changed
          bypass_sign_in(@user)
          flash[:success] = t('.success')
          format.html { redirect_to edit_profile_password_path }
        else
          format.html { render :edit, status: :unprocessable_entity, locals: { user: @user } }
        end
      end
    end

    private

    def update_password_params
      params.require(:user).permit(:password, :password_confirmation, :current_password)
    end

    def set_user
      @user = current_user
    end
  end
end

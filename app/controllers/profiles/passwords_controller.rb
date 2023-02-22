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
      if @user.update_with_password(update_password_params)

        # Sign in the user bypassing validation in case his password changed
        sign_in @user, bypass: true

        flash[:success] = I18n.t('profiles.password.update_success')
        redirect_to edit_profile_password_path
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(@user, partial: 'form',
                                                             locals: { user: @user })
          end

          format.html { render :edit, status: :unprocessable_entity }
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

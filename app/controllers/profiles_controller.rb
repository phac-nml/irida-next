# frozen_string_literal: true

# Controller for the user profile page
class ProfilesController < ApplicationController
  layout 'profiles'

  before_action :set_user

  # Get the profile page
  def show
    # No necessary code here
  end

  def update
    if @user.update(update_params)
      # TODO: Need to add a check to see if the email is the same as the current one

      # Sign in the user bypassing validation in case his password changed
      bypass_sign_in(@user)

      flash[:success] = I18n.t('profiles.update_success')
      redirect_to profile_path
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@user, partial: 'form',
                                                    locals: { user: @user })
        end

        format.html { render :show, status: :unprocessable_entity }
      end

    end
  end

  private

  def update_params
    params.require(:user).permit(:email)
  end

  def set_user
    @user = current_user
  end
end

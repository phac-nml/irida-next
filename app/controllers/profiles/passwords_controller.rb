class Profiles::PasswordsController < ApplicationController
  layout 'profiles'

  before_action :set_user

  def edit; end

  def update
    # Devise::Models::DatabaseAuthenticatable#update_with_password
    # Update record attributes when :current_password matches, otherwise returns error on :current_password.
    # It also automatically rejects :password and :password_confirmation if they are blank.
    if @user.update_with_password(update_password_params)

      # Sign in the user bypassing validation in case his password changed
      sign_in @user, bypass: true

      flash[:success] = 'Password successfully created'
      redirect_to edit_profile_password_path
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@user, partial: 'form',
                                                           locals: { user: @user })
        end

        format.html { render :show }
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

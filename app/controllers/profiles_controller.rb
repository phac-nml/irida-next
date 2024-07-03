# frozen_string_literal: true

# Controller for the user profile page
class ProfilesController < Profiles::ApplicationController
  # Get the profile page
  def show
    authorize! @user, to: :read?
    # No necessary code here
  end

  def update
    authorize! @user

    respond_to do |format|
      if @user.update(update_params)
        # Sign in the user bypassing validation in case their password changed
        bypass_sign_in(@user)
        flash[:success] = t('.success')
        format.html { redirect_to profile_path }
      else
        format.html { render :show, status: :unprocessable_entity, locals: { user: @user } }
      end
    end
  end

  private

  def update_params
    params.require(:user).permit(
      :email,
      :first_name,
      :last_name
    )
  end

  def current_page
    @current_page = t(:'profiles.sidebar.profile')
  end
end

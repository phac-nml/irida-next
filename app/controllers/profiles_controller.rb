# frozen_string_literal: true

# Controller for the user profile page
class ProfilesController < Profiles::ApplicationController
  before_action :page_title

  # Get the profile page
  def show
    authorize! @user, to: :read?
    # No necessary code here
  end

  def update
    authorize! @user

    respond_to do |format|
      if Users::UpdateService.new(current_user, @user, update_params).execute
        # Sign in the user bypassing validation in case their password changed
        bypass_sign_in(@user)
        flash[:success] = t('.success')
        format.html { redirect_to profile_path }
      else
        format.html { render :show, status: :unprocessable_content, locals: { user: @user } }
      end
    end
  end

  private

  def update_params
    params.expect(user: %i[email first_name last_name])
  end

  def current_page
    @current_page = t(:'profiles.sidebar.profile')
  end

  def page_title
    @title = [t(:'profiles.sidebar.profile'), current_user.email].join(' · ')
  end
end

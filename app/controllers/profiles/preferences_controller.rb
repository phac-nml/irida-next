# frozen_string_literal: true

# Purpose: To handle the user's site preferences
module Profiles
  # Controller for the user personal preferences page
  class PreferencesController < Profiles::ApplicationController
    def show
      authorize! @user, to: :read?
    end

    def current_page
      @current_page = 'preferences'
    end

    def update
      authorize! @user
      # if update_params[:locale] == 'en'
      #   flash[:success] = 'Language updated successfully'
      # elsif update_params[:locale] == 'fr'
      #   flash[:success] = 'Langue mise à jour avec succès'
      # end
      respond_to do |format|
        if @user.update(update_params)
          flash[:success] = t('.success')
          format.html { redirect_to profile_preferences_path }
        else
          format.html { render :show, status: :unprocessable_entity, locals: { user: @user } }
        end
      end
    end

    private

    def update_params
      params.require(:user).permit(
        :locale
      )
    end
  end
end

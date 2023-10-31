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
      respond_to do |format|
        if @user.update(update_params)
          # Success message is hardcoded here because using the translation still uses the old language
          # ie going from en to fr will use the en text. Hardcoding here will also simplify things in case
          # a 3rd language is added
          if update_params[:locale] == 'en'
            flash[:success] = 'Language updated successfully' # rubocop:disable Rails/I18nLocaleTexts
          elsif update_params[:locale] == 'fr'
            flash[:success] = 'Langue mise à jour avec succès' # rubocop:disable Rails/I18nLocaleTexts
          end
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

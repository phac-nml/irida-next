# frozen_string_literal: true

# Purpose: To handle the user's site preferences
module Profiles
  # Controller for the user personal preferences page
  class PreferencesController < Profiles::ApplicationController
    before_action :page_title

    def show
      authorize! @user, to: :read?
    end

    def current_page
      @current_page = t(:'profiles.sidebar.preferences')
    end

    def update # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      authorize! @user
      respond_to do |format|
        # Locale is called now rather than from the around_action in app_controller because we need the locale
        # change prior to the success flash so that the flash contains the correct translation
        updated = @user.update(update_params)
        if updated
          format.turbo_stream do
            render status: :ok, locals: { type: 'success', message: t('.success', locale: current_user.locale) }
          end
          format.html do
            flash[:success] = t('.success', locale: current_user.locale)
            redirect_back_or_to profile_preferences_path
          end
        else
          format.turbo_stream do
            render status: :unprocessable_content, locals: { type: 'error', message: t('.error') }
          end
          format.html do
            flash[:error] = t('.error')
            render :show, status: :unprocessable_content, locals: { user: @user }
          end
        end
      end
    end

    private

    def update_params
      params.expect(
        user: [:locale]
      )
    end

    def page_title
      @title = [t(:'profiles.sidebar.preferences'), current_user.email].join(' · ')
    end
  end
end

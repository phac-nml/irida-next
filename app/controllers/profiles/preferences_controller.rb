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
      updated = @user.update(update_params)

      respond_to do |format|
        if updated
          # Wrapping this in I18n.with_locale in case the user changed their language preference,
          # that way the toast message will be in the correction translation
          I18n.with_locale(@user.locale.to_sym) do
            format.turbo_stream do
              render status: :ok, locals: { type: 'success', message: t('.success') }
            end
            format.html do
              flash[:success] = t('.success')
              redirect_back_or_to profile_preferences_path
            end
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

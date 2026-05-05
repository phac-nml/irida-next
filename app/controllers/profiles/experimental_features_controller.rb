# frozen_string_literal: true

# Purpose: To handle user opt-in to experimental features via Flipper actor gates
module Profiles
  # Controller for the user experimental features opt-in page
  class ExperimentalFeaturesController < Profiles::ApplicationController
    def show
      authorize! @user, to: :read?
      @eligible_features = opt_in_service.eligible_features
    end

    def update
      authorize! @user, to: :update?
      result = update_service.execute(params:)

      respond_to do |format|
        format.turbo_stream { render_update_turbo_stream(result) }
        format.html { render_update_html(result) }
      end
    end

    def current_page
      @current_page = t(:'profiles.sidebar.experimental_features')
      @title = @current_page
    end

    private

    def render_update_turbo_stream(result)
      render :update,
             status: result.status,
             locals: {
               feature_key: result.feature_key,
               success: result.success?,
               feature: result.feature,
               message: result.message
             }
    end

    def render_update_html(result)
      if result.success?
        flash[:success] = t('.success')
      else
        flash[:error] = result.message
      end

      redirect_to profile_experimental_features_path
    end

    def opt_in_service
      @opt_in_service ||= Profiles::ExperimentalFeatures::OptInService.new(user: @user, locale: I18n.locale)
    end

    def update_service
      @update_service ||= Profiles::ExperimentalFeatures::UpdateService.new(user: @user, locale: I18n.locale)
    end
  end
end

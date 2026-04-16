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
      parsed_input = parse_update_input
      return unless parsed_input

      feature_key, enabled = parsed_input
      result = opt_in_service.toggle(feature_key:, enabled:)
      handle_toggle_result(feature_key, result)
    end

    def current_page
      @current_page = t(:'profiles.sidebar.experimental_features')
      @title = @current_page
    end

    private

    def parse_update_input
      feature_key = parsed_feature_key
      unless feature_key
        reject_invalid_params
        return nil
      end

      enabled = parsed_enabled
      if enabled.nil?
        reject_invalid_params(feature_key)
        return nil
      end

      [feature_key, enabled]
    end

    def handle_toggle_result(feature_key, result)
      return reject_ineligible_feature(feature_key) if result.error_key == :not_eligible
      return reject_toggle_error(feature_key, result.feature) unless result.success?

      render_toggle_success(feature_key, result.feature)
    end

    def render_toggle_success(feature_key, feature)
      respond_to do |format|
        format.turbo_stream do
          render :update, locals: { feature_key:, success: true, feature: }
        end
        format.html do
          flash[:success] = t('.success')
          redirect_to profile_experimental_features_path
        end
      end
    end

    def reject_ineligible_feature(feature_key)
      reject_request(:forbidden, 'profiles.experimental_features.update.not_eligible', feature_key:)
    end

    def reject_toggle_error(feature_key, feature)
      reject_request(:unprocessable_content, 'profiles.experimental_features.update.error', feature_key:, feature:)
    end

    def reject_invalid_params(feature_key = nil)
      reject_request(:unprocessable_content, 'profiles.experimental_features.update.error', feature_key:)
    end

    def reject_request(status, message_key, feature_key:, feature: nil)
      message = t(message_key)

      respond_to do |format|
        format.turbo_stream do
          render :update,
                 status:,
                 locals: { feature_key:, success: false, feature:, message: }
        end
        format.html do
          flash[:error] = message
          redirect_to profile_experimental_features_path
        end
      end
    end

    def parsed_feature_key
      raw_feature_key = params[:feature_key].to_s.strip
      return nil if raw_feature_key.blank?
      return nil unless /\A[a-z0-9_]+\z/.match?(raw_feature_key)

      raw_feature_key
    end

    def parsed_enabled
      return true if params[:enabled] == '1'
      return false if params[:enabled] == '0'

      nil
    end

    def opt_in_service
      @opt_in_service ||= Profiles::ExperimentalFeatures::OptInService.new(user: @user, locale: I18n.locale)
    end
  end
end

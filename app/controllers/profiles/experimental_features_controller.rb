# frozen_string_literal: true

# Purpose: To handle user opt-in to experimental features via Flipper actor gates
module Profiles
  # Controller for the user experimental features opt-in page
  class ExperimentalFeaturesController < Profiles::ApplicationController
    before_action :page_title

    def show
      authorize! @user, to: :read?
      @eligible_features = eligible_features_for(@user)
    end

    def update
      authorize! @user, to: :update?

      feature_key = params[:feature_key].to_sym

      return reject_ineligible_feature(feature_key) unless allowlisted_feature?(feature_key, @user)

      toggle_feature(feature_key)
    end

    def current_page
      @current_page = t(:'profiles.sidebar.experimental_features')
    end

    private

    def reject_ineligible_feature(feature_key)
      respond_to do |format|
        format.turbo_stream { render :update, locals: { feature_key:, success: false, feature: nil } }
        format.html do
          flash[:error] = t('.not_eligible')
          redirect_to profile_experimental_features_path
        end
      end
    end

    def toggle_feature(feature_key) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      enabled = params[:enabled] == '1'
      if enabled
        Flipper.enable_actor(feature_key, @user)
      else
        Flipper.disable_actor(feature_key, @user)
      end

      respond_to do |format|
        format.turbo_stream do
          render :update, locals: { feature_key:, success: true, feature: feature_hash_for(feature_key, enabled) }
        end
        format.html { redirect_to profile_experimental_features_path }
      end
    rescue StandardError => e
      Rails.logger.error "ExperimentalFeaturesController#update error: #{e.message}"
      respond_to do |format|
        format.turbo_stream do
          render :update, locals: { feature_key:, success: false, feature: { key: feature_key, enabled: !enabled } }
        end
        format.html do
          flash[:error] = t('.error')
          redirect_to profile_experimental_features_path
        end
      end
    end

    def eligible_features_for(user)
      features = USER_OPT_IN_FEATURE_CONFIG['user_opt_in_features']
      return [] if features.blank?

      features.filter_map do |key, feature_config|
        next unless user_eligible?(user, feature_config)

        feature_hash_for(key.to_sym, Flipper.enabled?(key.to_sym, user), feature_config)
      end
    end

    def feature_hash_for(key, enabled, feature_config = nil)
      feature_config ||= USER_OPT_IN_FEATURE_CONFIG.dig('user_opt_in_features', key.to_s)
      locale = I18n.locale.to_s
      {
        key:,
        enabled:,
        name: feature_config&.dig('name', locale) || feature_config&.dig('name', 'en'),
        description: feature_config&.dig('description', locale) || feature_config&.dig('description', 'en')
      }
    end

    def user_eligible?(_user, feature_config)
      feature_config['allowlist'] == 'all'
    end

    def allowlisted_feature?(key, user)
      features = USER_OPT_IN_FEATURE_CONFIG['user_opt_in_features']
      return false if features.blank?

      feature_config = features[key.to_s]
      return false if feature_config.nil?

      user_eligible?(user, feature_config)
    end

    def page_title
      @title = t(:'profiles.sidebar.experimental_features')
    end
  end
end

# frozen_string_literal: true

# Purpose: To handle user opt-in to experimental features via Flipper actor gates
module Profiles
  # Controller for the user experimental features opt-in page
  class ExperimentalFeaturesController < Profiles::ApplicationController # rubocop:disable Metrics/ClassLength
    before_action :page_title

    def show
      authorize! @user, to: :read?
      @eligible_features = eligible_features_for(@user)
    end

    def update
      authorize! @user, to: :update?

      feature_key = parsed_feature_key
      return reject_invalid_params unless feature_key

      enabled = parsed_enabled
      return reject_invalid_params(feature_key) if enabled.nil?

      return reject_ineligible_feature(feature_key) unless allowlisted_feature?(feature_key, @user)

      toggle_feature(feature_key, enabled)
    end

    def current_page
      @current_page = t(:'profiles.sidebar.experimental_features')
    end

    private

    def reject_ineligible_feature(feature_key)
      respond_to do |format|
        format.turbo_stream do
          render :update,
                 status: :forbidden,
                 locals: { feature_key:, success: false, feature: nil,
                           message: t('profiles.experimental_features.update.not_eligible') }
        end
        format.html do
          flash[:error] = t('profiles.experimental_features.update.not_eligible')
          redirect_to profile_experimental_features_path
        end
      end
    end

    def reject_invalid_params(feature_key = nil)
      respond_to do |format|
        format.turbo_stream do
          render :update,
                 status: :unprocessable_content,
                 locals: { feature_key:, success: false, feature: nil,
                           message: t('profiles.experimental_features.update.error') }
        end
        format.html do
          flash[:error] = t('profiles.experimental_features.update.error')
          redirect_to profile_experimental_features_path
        end
      end
    end

    def toggle_feature(feature_key, enabled) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      if enabled
        Flipper.enable_actor(feature_key, @user)
      else
        Flipper.disable_actor(feature_key, @user)
      end

      respond_to do |format|
        format.turbo_stream do
          render :update, locals: { feature_key:, success: true, feature: feature_hash_for(feature_key, enabled) }
        end
        format.html do
          flash[:success] = t('profiles.experimental_features.update.success')
          redirect_to profile_experimental_features_path
        end
      end
    rescue StandardError => e
      Rails.logger.error "ExperimentalFeaturesController#update error: #{e.message}"
      respond_to do |format|
        format.turbo_stream do
          render :update,
                 status: :unprocessable_content,
                 locals: { feature_key:, success: false, feature: { key: feature_key, enabled: !enabled },
                           message: t('profiles.experimental_features.update.error') }
        end
        format.html do
          flash[:error] = t('profiles.experimental_features.update.error')
          redirect_to profile_experimental_features_path
        end
      end
    end

    def eligible_features_for(user)
      features = USER_OPT_IN_FEATURE_CONFIG['user_opt_in_features']
      return [] if features.blank?

      features.filter_map do |key, feature_config|
        next unless user_eligible?(user, feature_config)

        feature_hash_for(key.to_sym, actor_opted_in?(key, user), feature_config)
      end
    end

    def actor_opted_in?(feature_key, user)
      Flipper[feature_key.to_sym].actors_value.include?(user.flipper_id)
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

    def user_eligible?(user, feature_config)
      allowlist = feature_config['allowlist']
      return true if allowlist == 'all'
      return false unless allowlist.is_a?(Array)

      user_email = user&.email.to_s.strip.downcase
      return false if user_email.blank?

      allowlist.any? { |email| email.to_s.strip.downcase == user_email }
    end

    def allowlisted_feature?(key, user)
      features = USER_OPT_IN_FEATURE_CONFIG['user_opt_in_features']
      return false if features.blank?

      feature_config = features[key.to_s]
      return false if feature_config.nil?

      user_eligible?(user, feature_config)
    end

    def parsed_feature_key
      raw_feature_key = params[:feature_key].to_s.strip
      return nil if raw_feature_key.blank?

      raw_feature_key.to_sym
    end

    def parsed_enabled
      return true if params[:enabled] == '1'
      return false if params[:enabled] == '0'

      nil
    end

    def page_title
      @title = t(:'profiles.sidebar.experimental_features')
    end
  end
end

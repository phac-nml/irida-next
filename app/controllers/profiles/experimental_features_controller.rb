# frozen_string_literal: true

module Profiles
  # Controller for user opt-in controls on experimental Flipper features
  class ExperimentalFeaturesController < Profiles::ApplicationController
    before_action :page_title

    def show
      authorize! @user, to: :read?
      @eligible_features = service.eligible_features
    end

    def update # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      authorize! @user, to: :update?

      form = build_form
      updated = Profiles::ExperimentalFeatures::OptInService.new(@user, form).execute
      feature = service.feature(form.feature_key, include_ineligible: !updated)
      status_message = updated ? t('.success') : status_message_for(form)
      status_variant = updated ? :success : :error

      respond_to do |format|
        format.turbo_stream do
          render :update,
                 status: updated ? :ok : :unprocessable_content,
                 locals: {
                   feature: feature,
                   user: @user,
                   status_message: status_message,
                   status_variant: status_variant
                 }
        end
        format.html do
          flash[updated ? :success : :error] = status_message
          redirect_back_or_to profile_experimental_features_path
        end
      end
    rescue ActionController::ParameterMissing
      respond_invalid_submission
    end

    private

    def service
      @service ||= Profiles::ExperimentalFeatures::OptInService.new(@user)
    end

    def build_form
      Profiles::ExperimentalFeatures::OptInForm.new(
        user: @user,
        **params.expect(opt_in_form: %i[feature_key enabled])
      )
    end

    def status_message_for(form)
      return t(:'profiles.experimental_features.update.error') if form_error?(form, :base, :flipper_error)
      return t(:'profiles.experimental_features.update.not_eligible') if form_error?(form, :feature_key, :not_eligible)

      t(:'profiles.experimental_features.update.validation_error')
    end

    def form_error?(form, field, error_key)
      form.errors.details[field].any? { |error| error[:error] == error_key }
    end

    def respond_invalid_submission
      respond_to do |format|
        format.turbo_stream { head :unprocessable_content }
        format.html do
          flash[:error] = t(:'profiles.experimental_features.update.validation_error')
          redirect_back_or_to profile_experimental_features_path
        end
      end
    end

    def current_page
      @current_page = t(:'profiles.sidebar.experimental_features')
    end

    def page_title
      @title = t(:'profiles.experimental_features.show.title')
    end
  end
end

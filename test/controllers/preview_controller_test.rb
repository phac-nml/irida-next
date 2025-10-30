# frozen_string_literal: true

require 'test_helper'

class PreviewControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # NOTE: PreviewController is used by Lookbook for component previews
  # Testing locale setting behavior with simulated params

  test 'inherits from ApplicationController' do
    assert_equal ApplicationController, PreviewController.superclass
  end

  test 'has lookbook layout configured' do
    # Check that the layout method is overridden
    # ViewComponent 4.x uses the layout method differently
    # We just verify the class has the layout configured
    assert_equal 'lookbook', PreviewController._layout
  end

  test 'set_locale uses params lang when provided' do
    I18n.with_locale(I18n.default_locale) do
      controller = PreviewController.new
      controller.params = ActionController::Parameters.new(
        lookbook: { display: { lang: 'fr' } }
      )

      controller.send(:set_locale)

      assert_equal :fr, I18n.locale
    end
  end

  test 'set_locale uses default locale when lang not provided' do
    controller = PreviewController.new
    controller.params = ActionController::Parameters.new(
      lookbook: { display: {} }
    )

    controller.send(:set_locale)

    assert_equal I18n.default_locale, I18n.locale
  end

  test 'set_locale uses default locale when lookbook params missing' do
    I18n.with_locale(I18n.default_locale) do
      controller = PreviewController.new
      controller.params = ActionController::Parameters.new({})

      controller.send(:set_locale)

      assert_equal I18n.default_locale, I18n.locale
    end
  end

  test 'set_locale uses default locale when lang is empty string' do
    I18n.with_locale(I18n.default_locale) do
      controller = PreviewController.new
      controller.params = ActionController::Parameters.new(
        lookbook: { display: { lang: '' } }
      )

      controller.send(:set_locale)

      assert_equal I18n.default_locale, I18n.locale
    end
  end

  test 'set_locale before_action is configured' do
    before_actions = PreviewController._process_action_callbacks.select do |callback|
      callback.kind == :before && callback.filter == :set_locale
    end

    assert before_actions.any?, 'set_locale should be configured as a before_action'
  end
end

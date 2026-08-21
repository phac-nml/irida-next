# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class FlashComponentTest < ViewComponentTestCase
    test 'renders success flash with correct icon, colors, and ARIA attributes' do
      message = 'This is a success message.'
      render_inline(Viral::FlashComponent.new(type: :success, data: message))

      assert_text message
      assert_selector "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']"
      assert_selector 'div.text-green-500.bg-green-100 svg.check-circle-icon'
      assert_selector 'div[aria-hidden="true"]' # Icon container hidden from screen readers
      assert_selector 'span.sr-only', text: I18n.t('common.statuses.success')
      assert_selector "button[aria-label='#{I18n.t('general.screen_reader.close')}']"
    end

    test 'renders error flash with correct icon, colors, and ARIA attributes' do
      message = 'This is an error message.'
      render_inline(Viral::FlashComponent.new(type: :error, data: message))

      assert_text message
      assert_selector "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='error']"
      assert_selector 'div.text-red-500.bg-red-100 svg.x-circle-icon'
      assert_selector 'div[aria-hidden="true"]' # Icon container hidden from screen readers
      assert_selector 'span.sr-only', text: I18n.t('common.statuses.error')
      assert_selector "button[aria-label='#{I18n.t('general.screen_reader.close')}']"
    end

    test 'renders warning flash with correct icon, colors, and ARIA attributes' do
      message = 'This is a warning message.'
      render_inline(Viral::FlashComponent.new(type: :warning, data: message))

      assert_text message
      assert_selector "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='warning']"
      assert_selector 'div.text-orange-500.bg-orange-100 svg.warning-circle-icon'
      assert_selector 'div[aria-hidden="true"]' # Icon container hidden from screen readers
      assert_selector 'span.sr-only', text: I18n.t('components.flash.warning_message')
      assert_selector "button[aria-label='#{I18n.t('general.screen_reader.close')}']"
    end

    test 'renders info flash with correct icon, colors, and ARIA attributes' do
      message = 'This is an info message.'
      render_inline(Viral::FlashComponent.new(type: :info, data: message))

      assert_text message
      assert_selector "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='info']"
      assert_selector 'div.text-blue-500.bg-blue-100 svg.info-icon'
      assert_selector 'div[aria-hidden="true"]' # Icon container hidden from screen readers
      assert_selector 'span.sr-only', text: I18n.t('components.flash.information_message')
      assert_selector "button[aria-label='#{I18n.t('general.screen_reader.close')}']"
    end

    test 'renders notice flash as info type' do
      message = 'This is a notice (info) message.'
      render_inline(Viral::FlashComponent.new(type: :notice, data: message))

      assert_text message
      assert_selector "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='info']"
      assert_selector 'div.text-blue-500.bg-blue-100 svg.info-icon'
      assert_selector 'div[aria-hidden="true"]' # Icon container hidden from screen readers
      assert_selector 'span.sr-only', text: I18n.t('components.flash.information_message')
      assert_selector "button[aria-label='#{I18n.t('general.screen_reader.close')}']"
    end

    test 'renders alert flash as error type' do
      message = 'This is an alert (error) message.'
      render_inline(Viral::FlashComponent.new(type: :error, data: message))

      assert_text message
      assert_selector "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='error']"
      assert_selector 'div.text-red-500.bg-red-100 svg.x-circle-icon'
      assert_selector 'div[aria-hidden="true"]' # Icon container hidden from screen readers
      assert_selector 'span.sr-only', text: I18n.t('common.statuses.error')
      assert_selector "button[aria-label='#{I18n.t('general.screen_reader.close')}']"
    end

    test 'error flash has no timeout by default' do
      render_inline(Viral::FlashComponent.new(type: :error, data: 'Error'))
      assert_selector "div[data-viral--flash-timeout-value='0']"
    end

    test 'non-error flash has default timeout' do
      render_inline(Viral::FlashComponent.new(type: :success, data: 'Success'))
      assert_selector "div[data-viral--flash-timeout-value='#{Viral::FlashComponent::DEFAULT_TIMEOUT}']"
    end

    test 'flash has unique id' do
      flash = Viral::FlashComponent.new(type: :success, data: 'Success')
      render_inline(flash)
      assert_selector "#toast-success-#{flash.object_id}"
    end

    test 'flash has proper aria-describedby attribute' do
      flash = Viral::FlashComponent.new(type: :success, data: 'Success')
      render_inline(flash)
      component_id = "toast-success-#{flash.object_id}"
      assert_selector "div[aria-describedby='#{component_id}-message']"
      assert_selector "div##{component_id}-message"
    end

    test 'flash has entrance animation styles' do
      render_inline(Viral::FlashComponent.new(type: :success, data: 'Success'))
      assert_selector 'div[style*="opacity: 0"]'
      assert_selector 'div[style*="transform: translateY(-20px) scale(0.95)"]'
    end
  end
end

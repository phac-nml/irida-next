# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class CancelButtonComponentTest < ViewComponent::TestCase
    test 'renders button with default cancel label' do
      render_inline(CancelButtonComponent.new)

      assert_selector 'button[type="button"]', text: I18n.t('components.pathogen.cancel_button.cancel')
    end

    test 'renders link when href is provided' do
      render_inline(CancelButtonComponent.new(href: '/groups'))

      assert_selector 'a[href="/groups"]', text: I18n.t('components.pathogen.cancel_button.cancel')
      assert_no_selector 'button'
    end

    test 'renders custom label when provided' do
      render_inline(CancelButtonComponent.new(label: 'Go back'))

      assert_selector 'button', text: 'Go back'
    end

    test 'forwards data attributes' do
      render_inline(CancelButtonComponent.new(data: { action: 'click->viral--dialog#close' }))

      assert_selector 'button[data-action="click->viral--dialog#close"]'
    end
  end
end

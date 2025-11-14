# frozen_string_literal: true

require 'test_helper'

module Layout
  class LanguageSelectionComponentTest < ViewComponentTestCase
    test 'renders the current locale name' do
      user = users(:john_doe)

      render_inline(Layout::LanguageSelectionComponent.new(user:))

      expected_text = I18n.t(:"locales.#{user.locale}", locale: user.locale)
      assert_selector '#language-selection-dd-label', text: expected_text
    end

    test 'falls back to default locale when user locale is invalid' do
      user = users(:john_doe)
      user.locale = 'not_a_locale'

      render_inline(Layout::LanguageSelectionComponent.new(user:))

      default_locale = I18n.default_locale
      expected_text = I18n.t(:"locales.#{default_locale}", locale: default_locale)
      assert_selector '#language-selection-dd-label', text: expected_text
    end
  end
end

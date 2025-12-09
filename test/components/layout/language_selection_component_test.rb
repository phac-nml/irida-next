# frozen_string_literal: true

require 'view_component_test_case'

module Layout
  class LanguageSelectionComponentTest < ViewComponentTestCase
    test 'renders the current locale name' do
      user = users(:john_doe)

      render_inline(Layout::LanguageSelectionComponent.new(user: user))

      expected_text = I18n.t(:"locales.#{user.locale}", locale: user.locale)
      assert_selector '#language-selection-dd-label', text: expected_text
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

module Layout
  class LanguageSelectionComponentTest < ViewComponentTestCase
    test 'renders language selection dropdown' do
      user = users(:john_doe)
      render_inline(Layout::LanguageSelectionComponent.new(user: user))

      assert_selector('button[aria-haspopup="true"]')
      assert_selector('ul[role="menu"]', visible: :all)
    end

    test 'user_locale returns user locale when user is present' do
      user = users(:john_doe)
      component = Layout::LanguageSelectionComponent.new(user: user)

      # user_locale returns the locale (could be string or symbol depending on DB storage)
      assert_equal user.locale.to_s, component.user_locale.to_s
    end

    test 'user_locale returns default locale when user is nil' do
      component = Layout::LanguageSelectionComponent.new(user: nil)

      assert_equal I18n.default_locale.to_s, component.user_locale.to_s
    end

    test 'user_locale returns default locale when user has no locale set' do
      user = users(:john_doe)
      # Stub the locale to return nil
      user.define_singleton_method(:locale) { nil }
      component = Layout::LanguageSelectionComponent.new(user: user)

      assert_equal I18n.default_locale.to_s, component.user_locale.to_s
    end

    test 'user_locale returns default locale when user locale is invalid' do
      user = users(:john_doe)
      # Stub the locale to return an invalid locale
      user.define_singleton_method(:locale) { 'invalid_locale' }
      component = Layout::LanguageSelectionComponent.new(user: user)

      assert_equal I18n.default_locale.to_s, component.user_locale.to_s
    end

    test 'user_locale returns default locale when user locale is empty string' do
      user = users(:john_doe)
      # Stub the locale to return an empty string
      user.define_singleton_method(:locale) { '' }
      component = Layout::LanguageSelectionComponent.new(user: user)

      assert_equal I18n.default_locale.to_s, component.user_locale.to_s
    end

    test 'renders with user locale displayed' do
      user = users(:john_doe)
      render_inline(Layout::LanguageSelectionComponent.new(user: user))

      locale_name = I18n.t(:"locales.#{user.locale}", locale: user.locale)
      assert_selector('span', text: locale_name)
      assert_selector('abbr', text: user.locale.to_s.upcase)
    end

    test 'renders all available locales in dropdown' do
      user = users(:john_doe)
      render_inline(Layout::LanguageSelectionComponent.new(user: user))

      # Check that the rendered content includes all locale names
      I18n.available_locales.each do |locale|
        locale_name = I18n.t(:"locales.#{locale}", locale: locale)
        assert rendered_content.include?(locale_name), "Expected to find locale '#{locale_name}' in rendered content"
      end
    end

    test 'marks current locale as checked in dropdown' do
      user = users(:john_doe)
      render_inline(Layout::LanguageSelectionComponent.new(user: user))

      assert_selector('li[role="menuitemradio"][aria-checked="true"]', visible: :all)
    end

    test 'includes form for changing locale' do
      user = users(:john_doe)
      render_inline(Layout::LanguageSelectionComponent.new(user: user))

      # Check for form and locale field (forms are inside hidden dropdown menu)
      assert_selector('form', visible: :all)
      assert_selector("input[type='hidden'][name='user[locale]']", visible: :all)
    end

    test 'renders translate icon' do
      user = users(:john_doe)
      render_inline(Layout::LanguageSelectionComponent.new(user: user))

      # Check that pathogen_icon helper is called (icon should be present in button)
      assert_selector('button svg, button img')
    end
  end
end

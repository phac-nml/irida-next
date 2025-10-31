# frozen_string_literal: true

module Layout
  # Component for rendering language selection dropdown.
  # Allows users to switch between available locales (en, fr).
  # Uses Current.user to determine selected locale.
  class LanguageSelectionComponent < Component
    def initialize(user: Current.user)
      @user = user
      @locale_options = I18n.available_locales.map { |locale| [I18n.t(:"locales.#{locale}", locale: locale), locale] }
    end

    # Returns the user's selected locale or default locale.
    # Validates that the locale is in the available locales list.
    #
    # @return [Symbol] Locale symbol (:en, :fr)
    def user_locale
      locale = @user&.locale
      return I18n.default_locale if locale.blank?

      locale_sym = locale.to_sym
      return locale_sym if I18n.available_locales.include?(locale_sym)

      I18n.default_locale
    end
  end
end

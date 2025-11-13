# frozen_string_literal: true

module Layout
  # Component for rendering language selection
  class LanguageSelectionComponent < Component
    attr_reader :locale

    def initialize(user: Current.user)
      @user = user
      @locale = @user&.locale || I18n.default_locale
      @locale_options = I18n.available_locales.map { |locale| [I18n.t(:"locales.#{locale}", locale: locale), locale] }
    end
  end
end

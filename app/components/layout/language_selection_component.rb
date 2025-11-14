# frozen_string_literal: true

module Layout
  # Component for rendering language selection
  class LanguageSelectionComponent < Component
    attr_reader :locale

    def initialize(user:)
      @locale = sanitized_locale(user&.locale)
      @locale_options = I18n.available_locales.map { |locale| [I18n.t(:"locales.#{locale}", locale: locale), locale] }
    end

    private

    def sanitized_locale(candidate_locale)
      locale = candidate_locale&.to_sym
      return locale if locale.present? && I18n.available_locales.include?(locale)

      I18n.default_locale
    end
  end
end

# frozen_string_literal: true

module Layout
  # Component for rendering language selection
  class LanguageSelectionComponent < Component
    def initialize(user: Current.user)
      @user = user
      @locale_options = I18n.available_locales.map { |locale| [I18n.t(:"locales.#{locale}"), locale] }
    end
  end
end

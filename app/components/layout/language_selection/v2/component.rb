# frozen_string_literal: true

module Layout
  module LanguageSelection
    module V2
      # Component for rendering language selection
      class Component < ::Component
        def initialize(user: Current.user)
          @user = user
          @locale_options = I18n.available_locales.map do |locale|
            [I18n.t(:"locales.#{locale}", locale: locale), locale]
          end
        end

        private

        def locale
          @user.locale.to_sym
        end
      end
    end
  end
end

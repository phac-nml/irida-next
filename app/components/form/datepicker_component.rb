# frozen_string_literal: true

module Form
  class DatepickerComponent < ViewComponent::Base
    def initialize(form:, value:)
      @form = form
      @value = value
    end
  end
end

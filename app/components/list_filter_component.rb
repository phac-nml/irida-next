# frozen_string_literal: true

class ListFilterComponent < Component
  attr_reader :form

  def initialize(form:)
    @form = form
  end
end

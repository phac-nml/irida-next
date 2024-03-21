# frozen_string_literal: true

# View component to add a dialog for filter table by a list
class ListFilterComponent < Component
  attr_reader :form

  def initialize(form:)
    @form = form
  end
end

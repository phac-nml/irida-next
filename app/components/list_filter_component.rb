# frozen_string_literal: true

# View component to add a dialog for filter table by a list
class ListFilterComponent < Component
  attr_reader :form, :filters

  def initialize(form:, filters:)
    @form = form
    @filters = filters
  end
end

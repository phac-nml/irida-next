# frozen_string_literal: true

# View component to add a dialog for filter table by a list
class ListFilterComponent < Component
  attr_reader :form, :samples

  def initialize(form:, samples:)
    @form = form
    @samples = samples
  end
end

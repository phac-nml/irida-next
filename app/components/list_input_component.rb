# frozen_string_literal: true

# View component for displaying a list within an input box
class ListInputComponent < Component
  attr_reader :list_input_form_name, :show_description

  def initialize(list_input_form_name:, show_description: true)
    @list_input_form_name = list_input_form_name
    @show_description = show_description
  end
end

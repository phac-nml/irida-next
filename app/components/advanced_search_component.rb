# frozen_string_literal: true

# View component for advanced search component
class AdvancedSearchComponent < Component
  renders_one :add_condition_button
  renders_one :add_group_button
  renders_one :remove_group_button

  def initialize(form:, search:, fields: [], operations: [])
    @search = search
    @form = form
    @fields = fields
    @operations = operations
  end
end

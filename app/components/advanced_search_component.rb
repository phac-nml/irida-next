# frozen_string_literal: true

# View component for advanced search component
class AdvancedSearchComponent < Component
  renders_one :add_condition_button
  renders_one :add_group_button
  renders_one :remove_group_button

  def initialize(form:, search:, fields: [], operations: [], scope: :sample_search)
    @form = form
    @search = search
    @fields = fields
    @operations = operations
    @scope = scope
  end
end

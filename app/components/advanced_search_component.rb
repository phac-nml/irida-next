# frozen_string_literal: true

# View component for advanced search component
class AdvancedSearchComponent < Component
  renders_one :add_condition_button
  renders_one :add_group_button
  renders_one :remove_group_button

  def initialize(form:, search:, fields: [], operations: [], open: false, status: true) # rubocop:disable Metrics/ParameterLists
    @form = form
    @search = search
    @fields = fields
    @operations = operations
    @open = open
    @status = status
  end
end

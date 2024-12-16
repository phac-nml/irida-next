# frozen_string_literal: true

# View component for advanced search component
class AdvancedSearchComponent < Component
  attr_reader :form, :filters

  renders_one :add_condition_button
  renders_one :add_group_button
  renders_one :remove_group_button

  def initialize(form:, filters:, metadata_fields: [], operations: [])
    @form = form
    @filters = filters
    @metadata_fields = metadata_fields
    @operations = operations
  end
end

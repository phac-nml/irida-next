# frozen_string_literal: true

# View component for advanced search component
class AdvancedSearchComponent < Component
  attr_reader :form, :filters

  def initialize(form:, filters:, metadata_fields: [], operations: [])
    @form = form
    @filters = filters
    @metadata_fields = metadata_fields
    @operations = operations
  end
end

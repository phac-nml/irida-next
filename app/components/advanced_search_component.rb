# frozen_string_literal: true

# View component for advanced search component
class AdvancedSearchComponent < Component
  def initialize(form:, search:, fields: [], open: false, status: true)
    @form = form
    @search = search
    @fields = fields
    @operations = operation_options
    @open = open
    @status = status
  end

  private

  def operation_options
    {
      I18n.t('advanced_search_component.operation.equals') => '=',
      I18n.t('advanced_search_component.operation.not_equals') => '!=',
      I18n.t('advanced_search_component.operation.less_than') => '<=',
      I18n.t('advanced_search_component.operation.greater_than') => '>=',
      I18n.t('advanced_search_component.operation.contains') => 'contains',
      I18n.t('advanced_search_component.operation.exists') => 'exists',
      I18n.t('advanced_search_component.operation.not_exists') => 'not_exists',
      I18n.t('advanced_search_component.operation.in') => 'in',
      I18n.t('advanced_search_component.operation.not_in') => 'not_in'
    }
  end
end

# frozen_string_literal: true

module WorkflowExecutionAdvancedSearchHelper
  def workflow_advanced_search_params(state:, operator: '=')
    {
      q: {
        groups_attributes: {
          '0' => {
            conditions_attributes: {
              '0' => {
                field: 'state',
                operator:,
                value: state
              }
            }
          }
        }
      }
    }
  end
end

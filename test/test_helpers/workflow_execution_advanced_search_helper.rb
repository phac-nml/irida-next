# frozen_string_literal: true

module WorkflowExecutionAdvancedSearchHelper
  def workflow_advanced_search_params(state:)
    {
      q: {
        groups_attributes: {
          '0' => {
            conditions_attributes: {
              '0' => {
                field: 'state',
                operator: '=',
                value: state
              }
            }
          }
        }
      }
    }
  end

  def workflow_advanced_search_ransack_groups_params(state:)
    {
      q: {
        groups: {
          conditions_attributes: {
            '0' => {
              field: 'state',
              operator: '=',
              value: state
            }
          }
        }
      }
    }
  end
end

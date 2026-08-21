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

  def assert_workflow_executions_table_headers(locale: I18n.locale)
    assert_select '#workflow-executions-table table thead' do
      assert_select 'th', I18n.t('workflow_executions.table_component.id', locale:)
      assert_select 'th', I18n.t('common.labels.name', locale:)
      assert_select 'th', I18n.t('workflow_executions.table_component.state', locale:)
      assert_select 'th', I18n.t('workflow_executions.table_component.run_id', locale:)
      assert_select 'th', I18n.t('workflow_executions.table_component.workflow_name', locale:)
      assert_select 'th', I18n.t('workflow_executions.table_component.workflow_version', locale:)
      assert_select 'th', I18n.t('workflow_executions.table_component.created_at', locale:)
      assert_select 'th', I18n.t('workflow_executions.table_component.updated_at', locale:)
    end
  end

  def assert_turbo_stream_flash(message, type: :success, locale: I18n.locale)
    status = I18n.t(type == :success ? 'common.statuses.success' : 'common.statuses.error', locale:)
    assert_select 'turbo-stream[action="append"][target="flashes"]' do
      assert_select 'template' do
        assert_select 'div[role="alert"]' do
          assert_select 'div', "#{status}: #{message}"
        end
      end
    end
  end

  def assert_workflow_execution_cancel_success(workflow_execution, expected_state:, locale: I18n.locale)
    assert_response :success
    assert_equal expected_state, workflow_execution.reload.state
    assert_turbo_stream_flash(
      I18n.t('concerns.workflow_execution_actions.cancel.success',
             workflow_name: workflow_execution.workflow.name,
             locale:),
      locale:
    )
    assert_select 'turbo-stream[action="refresh"]'
  end
end

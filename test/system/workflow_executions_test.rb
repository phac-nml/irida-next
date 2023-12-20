# frozen_string_literal: true

require 'application_system_test_case'

class WorkflowExecutionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:john_doe)
    login_as @user
  end

  test 'should display a list of workflow executions' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    assert_selector 'table#workflow_executions tbody tr', count: 5
  end
end

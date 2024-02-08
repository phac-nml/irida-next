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

  test 'should be able to cancel a workflow' do
    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: 'prepared').ancestor('tr')

    within tr do
      assert_selector 'td:nth-child(4)', text: 'prepared'
      assert_selector 'input[type="submit"][value="Cancel"]', count: 1
      find('input[type="submit"][value="Cancel"]').click
    end

    assert_text 'Confirmation required'
    click_button 'Confirm'

    assert_selector 'tbody tr td:nth-child(4)', text: 'canceling'
    assert_no_selector 'tbody tr input[type="submit"][value="Cancel"]'
  end
end

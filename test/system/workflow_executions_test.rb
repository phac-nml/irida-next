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

    assert_selector 'table#workflow_executions tbody tr', count: 12
  end

  test 'should be able to cancel a workflow' do
    workflow_execution = workflow_executions(:irida_next_example_prepared)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector 'td:nth-child(4)', text: workflow_execution.state
      assert_selector 'input[type="submit"][value="Cancel"]', count: 1
      find('input[type="submit"][value="Cancel"]').click
    end

    assert_text 'Confirmation required'
    click_button 'Confirm'

    assert_selector 'tbody tr td:nth-child(4)', text: 'canceling'
    assert_no_selector 'tbody tr  td:nth-child(4) input[type="submit"][value="Cancel"]'
  end

  test 'should not delete a prepared workflow' do
    workflow_execution = workflow_executions(:irida_next_example_prepared)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector 'td:nth-child(4)', text: workflow_execution.state
      assert_no_selector 'input[type="submit"][value="Delete"]'
    end
  end

  test 'should not delete a submitted workflow' do
    workflow_execution = workflow_executions(:irida_next_example_submitted)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector 'td:nth-child(4)', text: workflow_execution.state
      assert_no_selector 'input[type="submit"][value="Delete"]'
    end
  end

  test 'should delete a completed workflow' do
    workflow_execution = workflow_executions(:irida_next_example_completed)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector 'td:nth-child(4)', text: workflow_execution.state
      assert_selector 'input[type="submit"][value="Delete"]', count: 1
      find('input[type="submit"][value="Delete"]').click
    end

    assert_text 'Confirmation required'
    click_button 'Confirm'

    assert_no_text workflow_execution.id
  end

  test 'should delete an errored workflow' do
    workflow_execution = workflow_executions(:irida_next_example_error)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector 'td:nth-child(4)', text: workflow_execution.state
      assert_selector 'input[type="submit"][value="Delete"]', count: 1
      find('input[type="submit"][value="Delete"]').click
    end

    assert_text 'Confirmation required'
    click_button 'Confirm'

    assert_no_text workflow_execution.id
  end

  test 'should not delete a canceling workflow' do
    workflow_execution = workflow_executions(:irida_next_example_canceling)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector 'td:nth-child(4)', text: workflow_execution.state
      assert_no_selector 'input[type="submit"][value="Delete"]'
    end
  end

  test 'should delete a canceled workflow' do
    workflow_execution = workflow_executions(:irida_next_example_canceled)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector 'td:nth-child(4)', text: workflow_execution.state
      assert_selector 'input[type="submit"][value="Delete"]', count: 1
      find('input[type="submit"][value="Delete"]').click
    end

    assert_text 'Confirmation required'
    click_button 'Confirm'

    assert_no_text workflow_execution.id
  end

  test 'should not delete a running workflow' do
    workflow_execution = workflow_executions(:irida_next_example_running)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector 'td:nth-child(4)', text: workflow_execution.state
      assert_no_selector 'input[type="submit"][value="Delete"]'
    end
  end

  test 'should not delete a queued workflow' do
    workflow_execution = workflow_executions(:irida_next_example_queued)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector 'td:nth-child(4)', text: workflow_execution.state
      assert_no_selector 'input[type="submit"][value="Delete"]'
    end
  end

  test 'should not delete a new workflow' do
    workflow_execution = workflow_executions(:irida_next_example_new)

    visit workflow_executions_path

    assert_selector 'h1', text: I18n.t(:'workflow_executions.index.title')

    tr = find('td', text: workflow_execution.id).ancestor('tr')

    within tr do
      assert_selector 'td:nth-child(4)', text: workflow_execution.state
      assert_no_selector 'input[type="submit"][value="Delete"]'
    end
  end
end

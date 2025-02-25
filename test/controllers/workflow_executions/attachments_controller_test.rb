# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class AttachmentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:john_doe)
      sign_in @user
      @workflow_execution = workflow_executions(:workflow_execution_valid)
      @attachment = attachments(:project1Attachment2)
    end

    test 'index renders attachment view when attachment is present' do
      get workflow_executions_attachments_path(
        workflow_execution: @workflow_execution.id,
        attachment: @attachment.id
      )
      assert_response :success
      # Verify instance variables set by controller
      assert_not_nil controller.instance_variable_get(:@preview_type)
      assert_includes [true, false], controller.instance_variable_get(:@previewable)
      assert_includes [true, false], controller.instance_variable_get(:@copyable)
      # Verify breadcrumb navigation is generated
      context_crumbs = controller.instance_variable_get(:@context_crumbs)
      assert context_crumbs.is_a?(Array)
      assert_equal I18n.t('workflow_executions.index.title'), context_crumbs.first[:name]
    end

    test 'index renders file_not_found when attachment is missing' do
      get workflow_executions_attachments_path(
        workflow_execution: @workflow_execution.id,
        attachment: 999_999
      )
      assert_response :redirect
    end
  end
end

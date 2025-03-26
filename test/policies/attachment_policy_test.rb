# frozen_string_literal: true

require 'test_helper'

class AttachmentPolicyTest < ActiveSupport::TestCase
  test 'read? returns true for SamplesWorkflowExecution when user can read the workflow execution' do
    attachment = attachments(:samples_workflow_execution_completed_output_attachment)
    assert attachment.attachable.is_a?(SamplesWorkflowExecution)
    policy = AttachmentPolicy.new(attachment, user: users(:john_doe))

    assert policy.read?
  end

  test 'read? returns false for SamplesWorkflowExecution when user cannot read the workflow execution' do
    attachment = attachments(:samples_workflow_execution_completed_output_attachment)
    assert attachment.attachable.is_a?(SamplesWorkflowExecution)
    policy = AttachmentPolicy.new(attachment, user: users(:alph_abet))

    assert_not policy.read?
  end

  test 'read? returns true for ProjectNamespace when user can read the project' do
    attachment = attachments(:attachmentText)
    assert attachment.attachable.is_a?(Namespaces::ProjectNamespace)
    policy = AttachmentPolicy.new(attachment, user: users(:john_doe))

    assert policy.read?
  end

  test 'read? returns false for ProjectNamespace when user cannot read the project' do
    attachment = attachments(:attachmentText)
    assert attachment.attachable.is_a?(Namespaces::ProjectNamespace)
    policy = AttachmentPolicy.new(attachment, user: users(:alph_abet))

    assert_not policy.read?
  end

  test 'read? returns true for GroupNamespace when user can read the group' do
    attachment = attachments(:group1Attachment1)
    assert attachment.attachable.is_a?(Group)
    policy = AttachmentPolicy.new(attachment, user: users(:john_doe))

    assert policy.read?
  end

  test 'read? returns false for GroupNamespace when user cannot read the group' do
    attachment = attachments(:group1Attachment1)
    assert attachment.attachable.is_a?(Group)
    policy = AttachmentPolicy.new(attachment, user: users(:alph_abet))

    assert_not policy.read?
  end
end

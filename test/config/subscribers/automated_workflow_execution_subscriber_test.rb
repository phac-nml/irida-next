# frozen_string_literal: true

require 'test_helper'

module Subscribers
  class AutomatedWorkflowExecutionSubscriberTest < ActiveSupport::TestCase
    setup do
      Flipper.enable(:automated_workflow_execution_subscriber)
      @subscriber = AutomatedWorkflowExecutionSubscriber.new
      @attachable = samples(:sample1)
      @forward_attachment = attachments(:attachmentPEFWD1)
      @reverse_attachment = attachments(:attachmentPEREV1)
    end

    teardown do
      Flipper.disable(:automated_workflow_execution_subscriber)
    end

    test 'emit triggers AutomatedWorkflowExecutions::LaunchJob when paired-end attachments are present' do
      event = {
        name: 'attachments.create',
        payload: {
          attachable: @attachable,
          attachments: [@forward_attachment, @reverse_attachment]
        }
      }

      assert_enqueued_with(job: AutomatedWorkflowExecutions::LaunchJob) do
        @subscriber.emit(event)
      end
    end

    test 'emit triggers AutomatedWorkflowExecutions::LaunchJob when multiple paired-end attachments are present and the last pair is selected' do # rubocop:disable Layout/LineLength
      forward_attachment2 = attachments(:attachmentPEFWD2)
      reverse_attachment2 = attachments(:attachmentPEREV2)

      event = {
        name: 'attachments.create',
        payload: {
          attachable: @attachable,
          attachments: [@forward_attachment, @reverse_attachment, forward_attachment2, reverse_attachment2]
        }
      }

      assert_enqueued_with(job: AutomatedWorkflowExecutions::LaunchJob,
                           args: [@attachable,
                                  { 'forward' => forward_attachment2, 'reverse' => reverse_attachment2 }]) do
        @subscriber.emit(event)
      end
    end

    test 'emit does not trigger AutomatedWorkflowExecutions::LaunchJob when no paired-end attachments are present' do
      single_attachment = attachments(:attachment1)

      event = {
        name: 'attachments.create',
        payload: {
          attachable: @attachable,
          attachments: [single_attachment]
        }
      }

      assert_no_enqueued_jobs do
        @subscriber.emit(event)
      end
    end
  end
end

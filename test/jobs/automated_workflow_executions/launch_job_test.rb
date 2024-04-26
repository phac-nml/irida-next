# frozen_string_literal: true

require 'test_helper'
require 'minitest/autorun'

module AutomatedWorkflowExecutions
  class LaunchJobTest < ActiveJob::TestCase
    def setup
      @user = users(:jeff_doe)
      @sample = samples(:sampleB)
      @pe_attachment_pair = { 'forward' => attachments(:attachmentPEFWD1), 'reverse' => attachments(:attachmentPEREV1) }
    end

    test 'calls AutomatedWorkflowExecutions::LaunchService for each configured AutomatedWorkflowExecution' do
      count = 0
      mock = Minitest::Mock.new
      def mock.execute(*) = true

      AutomatedWorkflowExecutions::LaunchService.stub :new, lambda { |*|
                                                              count += 1
                                                              mock
                                                            } do
        AutomatedWorkflowExecutions::LaunchJob.perform_now(@sample, @pe_attachment_pair)
      end
      assert_equal 3, count
    end

    test 'doesn\'t call AutomatedWorkflowExecutions::LaunchService when no configured AutomatedWorkflowExecutions' do
      count = 0
      mock = Minitest::Mock.new
      def mock.execute(*) = true

      AutomatedWorkflowExecutions::LaunchService.stub :new, lambda { |*|
                                                              count += 1
                                                              mock
                                                            } do
        AutomatedWorkflowExecutions::LaunchJob.perform_now(samples(:sample3), nil)
      end
      assert_equal 0, count
    end
  end
end

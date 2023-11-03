# frozen_string_literal: true

require 'test_helper'

module Attachments
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample = samples(:sample1)
      @attachment1 = attachments(:attachment1)
      @attachment2 = attachments(:attachment2)
      @testsample_illumina_pe_fwd_blob = active_storage_blobs(:testsample_illumina_pe_forward_blob)
      @testsample_illumina_pe_rev_blob = active_storage_blobs(:testsample_illumina_pe_reverse_blob)
    end

    test 'delete attachment with correct permissions' do
      assert_difference -> { Attachment.count } => -1 do
        Attachments::DestroyService.new(@sample, @attachment1, @user).execute
      end
    end

    test 'delete attachment with incorrect permissions' do
      user = users(:joan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Attachments::DestroyService.new(@sample, @attachment1, user).execute
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :destroy?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.destroy?', name: @sample.project.name),
                   exception.result.message
    end

    test 'delete attachment with associated attachment' do
      @attachment2.metadata['associated_attachment_id'] = @attachment1.id
      assert_difference -> { Attachment.count } => -2 do
        Attachments::DestroyService.new(@sample, @attachment2, @user).execute
      end
    end
  end
end

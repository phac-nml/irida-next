# frozen_string_literal: true

require 'test_helper'

module Attachments
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample = samples(:sample1)
      @attachment1 = attachments(:attachment1)
      @attachment2 = attachments(:attachment2)
      @attachment3 = attachments(:attachmentA)
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
      assert_equal :destroy_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.destroy_sample?', name: @sample.project.name),
                   exception.result.message
    end

    test 'delete attachment with associated attachment' do
      @attachment2.metadata['associated_attachment_id'] = @attachment1.id
      assert_difference -> { Attachment.count } => -2 do
        Attachments::DestroyService.new(@sample, @attachment2, @user).execute
      end
    end

    test 'delete attachment that does not belong to sample' do
      assert_no_difference ['Attachment.count'] do
        Attachments::DestroyService.new(@sample, @attachment3, @user).execute
      end

      assert @attachment3.errors.full_messages.include?(
        I18n.t('services.attachments.destroy.does_not_belong_to_attachable')
      )
    end
  end
end

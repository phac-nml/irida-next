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

      @prev_timestamp = @sample.attachments_updated_at
    end

    test 'delete attachment with correct permissions' do
      assert_not_nil @sample.attachments_updated_at

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => -1 do
          Attachments::DestroyService.new(@sample, @attachment1, @user).execute
        end

        assert_not_equal @sample.reload.attachments_updated_at, @prev_timestamp
      end
    end

    test 'delete attachment with incorrect permissions' do
      user = users(:joan_doe)

      Timecop.travel(Time.zone.now + 5) do
        exception = assert_raises(ActionPolicy::Unauthorized) do
          Attachments::DestroyService.new(@sample, @attachment1, user).execute
        end

        assert_equal SamplePolicy, exception.policy
        assert_equal :destroy_attachment?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.sample.destroy_attachment?', name: @sample.name),
                     exception.result.message

        assert_equal @sample.reload.attachments_updated_at, @prev_timestamp
      end
    end

    test 'delete attachment with associated attachment' do
      @attachment2.metadata['associated_attachment_id'] = @attachment1.id

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => -2 do
          Attachments::DestroyService.new(@sample, @attachment2, @user).execute
        end

        assert_not_equal @sample.reload.attachments_updated_at, @prev_timestamp
      end
    end

    test 'delete attachment that does not belong to sample' do
      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference ['Attachment.count'] do
          Attachments::DestroyService.new(@sample, @attachment3, @user).execute
        end

        assert @attachment3.errors.full_messages.include?(
          I18n.t('services.attachments.destroy.does_not_belong_to_attachable')
        )

        assert_equal @sample.reload.attachments_updated_at, @prev_timestamp
      end
    end
  end
end

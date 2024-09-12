# frozen_string_literal: true

require 'test_helper'

module Attachments
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample = samples(:sample1)
      @project1 = projects(:project1)
      @group1 = groups(:group_one)
      @attachment1 = attachments(:attachment1)
      @attachment2 = attachments(:attachment2)
      @attachment3 = attachments(:attachmentA)
      @project1_attachment1 = attachments(:project1Attachment1)
      @group1_attachment1 = attachments(:group1Attachment1)

      @sample_prev_timestamp = @sample.attachments_updated_at
      @project_prev_timestamp = @project1.namespace.attachments_updated_at
      @group_prev_timestamp = @group1.attachments_updated_at
    end

    test 'delete attachment with correct permissions' do
      assert_not_nil @sample.attachments_updated_at
      puts @attachment1.associated_attachment
      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => -1 do
          Attachments::DestroyService.new(@sample, @attachment1, @user).execute
        end

        assert_not_equal @sample.reload.attachments_updated_at, @sample_prev_timestamp
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

        assert_equal @sample.reload.attachments_updated_at, @sample_prev_timestamp
      end
    end

    test 'delete attachment with associated attachment' do
      @attachment2.metadata['associated_attachment_id'] = @attachment1.id

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => -2 do
          Attachments::DestroyService.new(@sample, @attachment2, @user).execute
        end

        assert_not_equal @sample.reload.attachments_updated_at, @sample_prev_timestamp
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

        assert_equal @sample.reload.attachments_updated_at, @sample_prev_timestamp
      end
    end

    test 'delete project attachment with correct permissions' do
      assert_not_nil @project1.namespace.attachments_updated_at
      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => -1 do
          Attachments::DestroyService.new(@project1.namespace, @project1_attachment1, @user).execute
        end

        assert_not_equal @project1.namespace.reload.attachments_updated_at, @project_prev_timestamp
      end
    end

    test 'delete project attachment with incorrect permissions' do
      user = users(:joan_doe)

      Timecop.travel(Time.zone.now + 5) do
        exception = assert_raises(ActionPolicy::Unauthorized) do
          Attachments::DestroyService.new(@project1.namespace, @project1_attachment1, user).execute
        end

        assert_equal ProjectPolicy, exception.policy
        assert_equal :destroy_attachment?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.project.destroy_attachment?', name: @project1.name),
                     exception.result.message

        assert_equal @project1.namespace.reload.attachments_updated_at, @project_prev_timestamp
      end
    end

    test 'delete group attachment with correct permissions' do
      assert_not_nil @group1.attachments_updated_at
      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => -1 do
          Attachments::DestroyService.new(@group1, @group1_attachment1, @user).execute
        end

        assert_not_equal @group1.reload.attachments_updated_at, @group_prev_timestamp
      end
    end

    test 'delete group attachment with incorrect permissions' do
      user = users(:jane_doe)

      Timecop.travel(Time.zone.now + 5) do
        exception = assert_raises(ActionPolicy::Unauthorized) do
          Attachments::DestroyService.new(@group1, @group1_attachment1, user).execute
        end

        assert_equal GroupPolicy, exception.policy
        assert_equal :destroy_attachment?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.group.destroy_attachment?', name: @group1.name),
                     exception.result.message

        assert_equal @group1.reload.attachments_updated_at, @group_prev_timestamp
      end
    end
  end
end

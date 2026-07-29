# frozen_string_literal: true

require 'active_job/continuation/test_helper'
require 'test_helper'

module Samples
  class TransferJobTest < ActiveJob::TestCase
    include ActiveJob::Continuation::TestHelper

    def setup # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      Flipper.enable(:v2_sample_transfer)

      @john_doe = users(:john_doe)
      @jane_doe = users(:jane_doe)
      @joan_doe = users(:joan_doe)
      @ryan_doe = users(:ryan_doe)
      @current_project = projects(:project1)
      @new_project = projects(:project2)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)

      @sample33 = samples(:sample33)
      @sample34 = samples(:sample34)
      @sample35 = samples(:sample35)
      @project29 = projects(:project29)
      @project30 = projects(:project30)
      @project31 = projects(:project31)
      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12b = groups(:subgroup_twelve_b)
      @subgroup12aa = groups(:subgroup_twelve_a_a)
      @sample_transfer_params1 = { new_project_id: @project30.id,
                                   sample_ids: [@sample34.id, @sample35.id] }
      @sample_transfer_params2 = { new_project_id: @project29.id,
                                   sample_ids: [@sample33.id, @sample34.id, @sample35.id] }

      @john_doe_project2 = projects(:john_doe_project2)

      @group = groups(:group_one)
    end

    test 'transfer project samples with permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
        Samples::TransferJobV2.perform_now(
          @current_project.namespace,
          @john_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids],
          nil
        )
      end
    end

    test 'transfer project samples with maintainer permission within hierarchy' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
        Samples::TransferJobV2.perform_now(
          @current_project.namespace,
          @joan_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids],
          nil
        )
      end
    end

    test 'transfer project samples with maintainer permission but outside of hierarchy' do
      new_project = projects(:project32)

      @sample_transfer_params = { new_project_id: new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_no_changes -> { @sample1.reload.project.id } do
        Samples::TransferJobV2.perform_now(
          @current_project.namespace,
          @joan_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end

      assert @current_project.namespace.errors.full_messages.include?(
        I18n.t('services.samples.transfer.maintainer_transfer_not_allowed')
      )
    end

    test 'transfer project samples without specifying details' do
      assert_empty Samples::TransferJobV2.perform_now(@current_project.namespace, @john_doe, nil, nil)

      assert @current_project.namespace.errors.full_messages.include?(
        I18n.t('services.samples.transfer.invalid_new_project')
      )
    end

    test 'transfer project samples to existing project' do
      @sample_transfer_params = { new_project_id: @current_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_empty Samples::TransferJobV2.perform_now(
        @current_project.namespace,
        @john_doe,
        @sample_transfer_params[:new_project_id],
        @sample_transfer_params[:sample_ids],
        nil
      )
    end

    test 'authorize allowed to transfer project samples with project permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_authorized_to(:transfer_sample?, @current_project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Samples::TransferJobV2.perform_now(
          @current_project.namespace,
          @john_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids],
          nil
        )
      end
    end

    test 'authorize allowed to transfer project samples with target project permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_authorized_to(:transfer_sample_into_project?, @new_project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Samples::TransferJobV2.perform_now(
          @current_project.namespace,
          @john_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end
    end

    test 'transfer project samples without permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::TransferJobV2.perform_now(
          @current_project.namespace,
          @jane_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :transfer_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.transfer_sample?',
                          name: @current_project.name),
                   exception.result.message
    end

    test 'samples transfer with interrupt' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_equal(2, @project31.samples.count)
      assert_equal(1, @project29.samples.count)
      assert_equal(1, @project30.samples.count)

      Samples::TransferJobV2.perform_later(
        @group12,
        @john_doe,
        @project29.id,
        [@sample33.id, @sample34.id, @sample35.id]
      )

      assert_no_changes -> { @group12.reload.samples_count } do
        interrupt_job_during_step(Samples::TransferJobV2, :transfer_step, cursor: 1) do
          perform_enqueued_jobs(only: Samples::TransferJobV2)
        end
      end

      # verify only some samples transferred
      assert_equal(0, @project31.samples.count)
      assert_equal(3, @project29.samples.count)
      assert_equal(1, @project30.samples.count)

      # continue the job queue
      perform_enqueued_jobs(only: Samples::TransferJobV2)

      # verify all the counts updated
      assert_equal(0, @project31.samples.count)
      assert_equal(4, @project29.samples.count)
      assert_equal(0, @project30.samples.count)
    end

    test 'metadata summary updates after sample transfer' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

      assert_no_changes -> { @group12.reload.metadata_summary } do
        Samples::TransferJobV2.perform_now(
          @project31.namespace,
          @john_doe,
          @sample_transfer_params1[:new_project_id],
          @sample_transfer_params1[:sample_ids]
        )
      end

      assert_equal({}, @project31.namespace.reload.metadata_summary)
      assert_equal({}, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12b.reload.metadata_summary)

      assert_no_changes -> { @group12.reload.metadata_summary } do
        Samples::TransferJobV2.perform_now(
          @project30.namespace,
          @john_doe,
          @sample_transfer_params2[:new_project_id],
          @sample_transfer_params2[:sample_ids]
        )
      end

      assert_equal({}, @project30.namespace.reload.metadata_summary)
      assert_equal({}, @project31.namespace.reload.metadata_summary)
      assert_equal({}, @subgroup12b.reload.metadata_summary)
      assert_equal({}, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @subgroup12a.reload.metadata_summary)
    end

    test 'metadata summary updates after sample transfer with interrupt' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

      Samples::TransferJobV2.perform_later(
        @group12,
        @john_doe,
        @project29.id,
        [@sample33.id, @sample34.id, @sample35.id]
      )

      assert_no_changes -> { @group12.reload.metadata_summary } do
        interrupt_job_during_step(Samples::TransferJobV2, :update_metadata_step, cursor: 1) do
          perform_enqueued_jobs(only: Samples::TransferJobV2)
        end
      end

      # verify transfer step occurred
      assert_equal(0, @project31.samples.count) # actual
      assert_equal(4, @project29.samples.count) # actual
      assert_equal(0, @project30.samples.count) # actual

      assert_equal({}, @project31.namespace.reload.metadata_summary) # updated
      assert_equal({}, @subgroup12aa.reload.metadata_summary) # updated
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.reload.metadata_summary) # not updated
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.reload.metadata_summary) # not updated
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary) # remains unchanged

      # continue the job queue
      perform_enqueued_jobs(only: Samples::TransferJobV2)

      assert_equal({}, @project30.namespace.reload.metadata_summary)
      assert_equal({}, @project31.namespace.reload.metadata_summary)
      assert_equal({}, @subgroup12b.reload.metadata_summary)
      assert_equal({}, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @subgroup12a.reload.metadata_summary)
    end

    test 'samples count updates after sample transfer' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_equal(2, @subgroup12aa.samples_count)
      assert_equal(3, @subgroup12a.samples_count)
      assert_equal(1, @subgroup12b.samples_count)
      assert_equal(4, @group12.samples_count)

      assert_no_changes -> { @group12.reload.samples_count } do
        Samples::TransferJobV2.perform_now(
          @project31.namespace,
          @john_doe,
          @sample_transfer_params1[:new_project_id],
          @sample_transfer_params1[:sample_ids]
        )
      end

      assert_equal(0, @subgroup12aa.reload.samples_count)
      assert_equal(1, @subgroup12a.reload.samples_count)
      assert_equal(3, @subgroup12b.reload.samples_count)

      assert_no_changes -> { @group12.reload.samples_count } do
        Samples::TransferJobV2.perform_now(
          @project30.namespace,
          @john_doe,
          @sample_transfer_params2[:new_project_id],
          @sample_transfer_params2[:sample_ids]
        )
      end

      assert_equal(0, @subgroup12aa.reload.samples_count)
      assert_equal(4, @subgroup12a.reload.samples_count)
      assert_equal(0, @subgroup12b.reload.samples_count)
    end

    test 'samples count updates after sample transfer interrupt' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_equal(2, @subgroup12aa.samples_count)
      assert_equal(3, @subgroup12a.samples_count)
      assert_equal(1, @subgroup12b.samples_count)
      assert_equal(4, @group12.samples_count)

      Samples::TransferJobV2.perform_later(
        @group12,
        @john_doe,
        @project29.id,
        [@sample33.id, @sample34.id, @sample35.id]
      )

      assert_no_changes -> { @group12.reload.samples_count } do
        interrupt_job_during_step(Samples::TransferJobV2, :update_counts_and_activities_step, cursor: 1) do
          perform_enqueued_jobs(only: Samples::TransferJobV2)
        end
      end

      # verify only some of the counts updated
      assert_equal(0, @subgroup12aa.reload.samples_count) # updated correctly
      assert_equal(0, @project31.samples.count) # actual
      assert_equal(3, @subgroup12a.reload.samples_count) # not updated
      assert_equal(4, @project29.samples.count) # actual
      assert_equal(1, @subgroup12b.reload.samples_count) # not updated
      assert_equal(0, @project30.samples.count) # actual

      # continue the job queue
      perform_enqueued_jobs(only: Samples::TransferJobV2)

      # verify all the counts updated
      assert_equal(0, @subgroup12aa.reload.samples_count)
      assert_equal(0, @project31.samples.count) # actual

      assert_equal(4, @subgroup12a.reload.samples_count)
      assert_equal(4, @project29.samples.count) # actual

      assert_equal(0, @subgroup12b.reload.samples_count)
      assert_equal(0, @project30.samples.count) # actual
    end

    test 'samples count updates after a sample transfer from a user namespace' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      sample24 = samples(:sample24)

      assert_difference -> { @subgroup12aa.reload.samples_count } => 1,
                        -> { @subgroup12a.reload.samples_count } => 1,
                        -> { @subgroup12b.reload.samples_count } => 0,
                        -> { @group12.reload.samples_count } => 1,
                        -> { @john_doe_project2.reload.samples.size } => -1 do
        Samples::TransferJobV2.perform_now(
          @john_doe_project2.namespace,
          @john_doe,
          @project31.id,
          [sample24.id]
        )
      end
    end

    test 'samples count updates after a sample transfer to a user namespace' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_difference -> { @subgroup12aa.reload.samples_count } => -2,
                        -> { @subgroup12a.reload.samples_count } => -2,
                        -> { @subgroup12b.reload.samples_count } => 0,
                        -> { @group12.reload.samples_count } => -2,
                        -> { @john_doe_project2.reload.samples.size } => 2 do
        Samples::TransferJobV2.perform_now(
          @project31.namespace,
          @john_doe,
          @john_doe_project2.id,
          [@sample34.id, @sample35.id]
        )
      end
    end

    test 'samples count updates after a sample transfer between projects in the same user namespace' do
      john_doe_project3 = projects(:john_doe_project3)
      sample24 = samples(:sample24)

      assert_difference -> { @john_doe_project2.reload.samples.size } => -1,
                        -> { john_doe_project3.reload.samples.size } => 1 do
        Samples::TransferJobV2.perform_now(@john_doe_project2.namespace, @john_doe, john_doe_project3.id, [sample24.id])
      end
    end

    test 'transfer group samples with permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
        Samples::TransferJobV2.perform_now(
          @group,
          @john_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end
    end

    test 'transfer group samples with maintainer permission within hierarchy' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
        Samples::TransferJobV2.perform_now(
          @group,
          @joan_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end
    end

    test 'transfer group samples with maintainer permission but outside of hierarchy' do
      new_project = projects(:project32)

      @sample_transfer_params = { new_project_id: new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_no_changes -> { @sample1.reload.project.id } do
        Samples::TransferJobV2.perform_now(
          @group,
          @joan_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end

      assert @group.errors.messages_for(:base).first.include?(
        I18n.t('services.samples.transfer.maintainer_transfer_not_allowed')
      )
    end

    test 'transfer group samples the user is not authorized to do so' do
      new_project = projects(:project32)
      sample = samples(:group_sample_transfer_sample1)

      sample_transfer_params = { new_project_id: new_project.id,
                                 sample_ids: [sample.id] }

      assert_no_changes -> { sample.reload.project.id } do
        Samples::TransferJobV2.perform_now(
          @group,
          @john_doe,
          sample_transfer_params[:new_project_id],
          sample_transfer_params[:sample_ids]
        )
      end

      assert @group.errors.messages_for(:samples).first.include?(
        I18n.t('services.samples.transfer.unauthorized', sample_ids: sample.id)
      )
    end

    test 'transfer group samples that do not exist' do
      new_project = projects(:project32)

      sample_transfer_params = { new_project_id: new_project.id,
                                 sample_ids: ['123'] }

      Samples::TransferJobV2.perform_now(
        @group,
        @john_doe,
        sample_transfer_params[:new_project_id],
        sample_transfer_params[:sample_ids]
      )

      assert @group.errors.messages_for(:samples).first.include?(
        I18n.t('services.samples.transfer.samples_not_found', sample_ids: '123')
      )
    end

    test 'transfer group samples the user is not authorized to do so and transfer group samples that do not exist' do
      new_project = projects(:project32)
      sample = samples(:group_sample_transfer_sample1)

      sample_transfer_params = { new_project_id: new_project.id,
                                 sample_ids: [sample.id, '123'] }

      assert_no_changes -> { sample.reload.project.id } do
        Samples::TransferJobV2.perform_now(
          @group,
          @john_doe,
          sample_transfer_params[:new_project_id],
          sample_transfer_params[:sample_ids]
        )
      end

      assert @group.errors.messages_for(:samples).include?(
        I18n.t('services.samples.transfer.unauthorized', sample_ids: sample.id)
      )

      assert @group.errors.messages_for(:samples).include?(
        I18n.t('services.samples.transfer.samples_not_found', sample_ids: '123')
      )
    end

    test 'transfer group samples without specifying details' do
      assert_empty Samples::TransferJobV2.perform_now(
        @group,
        @john_doe,
        nil,
        nil
      )

      assert @group.errors.full_messages.include?(
        I18n.t('services.samples.transfer.invalid_new_project')
      )
    end

    test 'transfer group samples to existing project' do
      @sample_transfer_params = { new_project_id: @current_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_empty Samples::TransferJobV2.perform_now(
        @group,
        @john_doe,
        @sample_transfer_params[:new_project_id],
        @sample_transfer_params[:sample_ids]
      )
    end

    test 'authorize allowed to transfer group samples with project permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_authorized_to(:transfer_sample?, @group,
                           with: GroupPolicy,
                           context: { user: @john_doe }) do
        Samples::TransferJobV2.perform_now(
          @group,
          @john_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end
    end

    test 'authorize allowed to transfer group samples with target project permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_authorized_to(:transfer_sample_into_project?, @new_project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Samples::TransferJobV2.perform_now(
          @group,
          @john_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end
    end

    test 'transfer group samples without permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::TransferJobV2.perform_now(
          @group,
          @ryan_doe,
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :transfer_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.transfer_sample?',
                          name: @group.name),
                   exception.result.message
    end

    test 'metadata summary updates after group sample transfer' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 },
                   @group12.metadata_summary)

      assert_no_changes -> { @group12.reload.metadata_summary } do
        Samples::TransferJobV2.perform_now(
          @subgroup12aa,
          @john_doe,
          @sample_transfer_params1[:new_project_id],
          @sample_transfer_params1[:sample_ids]
        )
      end

      assert_equal({}, @project31.namespace.reload.metadata_summary)
      assert_equal({}, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @project30.namespace.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12b.reload.metadata_summary)

      assert_no_changes -> { @group12.reload.metadata_summary } do
        Samples::TransferJobV2.perform_now(
          @subgroup12b,
          @john_doe,
          @sample_transfer_params2[:new_project_id],
          @sample_transfer_params2[:sample_ids]
        )
      end

      assert_equal({}, @project30.namespace.reload.metadata_summary)
      assert_equal({}, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @project29.namespace.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @subgroup12a.reload.metadata_summary)
      assert_equal({}, @subgroup12b.reload.metadata_summary)
    end

    test 'metadata summary updates after group sample transfer when group is ancestor of source and dest projects' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 },
                   @group12.metadata_summary)

      assert_no_changes -> { @group12.reload.metadata_summary } do
        Samples::TransferJobV2.perform_now(
          @group12,
          @john_doe,
          @sample_transfer_params1[:new_project_id],
          @sample_transfer_params1[:sample_ids]
        )
      end

      assert_equal({}, @project31.namespace.reload.metadata_summary)
      assert_equal({}, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @project30.namespace.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12b.reload.metadata_summary)
    end

    test 'samples count updates after group sample transfer' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_equal(2, @subgroup12aa.samples_count)
      assert_equal(3, @subgroup12a.samples_count)
      assert_equal(1, @subgroup12b.samples_count)
      assert_equal(4, @group12.samples_count)

      assert_no_changes -> { @group12.reload.samples_count } do
        Samples::TransferJobV2.perform_now(
          @subgroup12aa,
          @john_doe,
          @sample_transfer_params1[:new_project_id],
          @sample_transfer_params1[:sample_ids]
        )
      end

      assert_equal(0, @subgroup12aa.reload.samples_count)
      assert_equal(1, @subgroup12a.reload.samples_count)
      assert_equal(3, @subgroup12b.reload.samples_count)

      assert_no_changes -> { @group12.reload.samples_count } do
        Samples::TransferJobV2.perform_now(
          @subgroup12b,
          @john_doe,
          @sample_transfer_params2[:new_project_id],
          @sample_transfer_params2[:sample_ids]
        )
      end

      assert_equal(0, @subgroup12b.reload.samples_count)
      assert_equal(4, @subgroup12a.reload.samples_count)
    end

    test 'samples count updates after group sample transfer when group is ancestor of source and dest projects' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_equal(2, @subgroup12aa.samples_count)
      assert_equal(3, @subgroup12a.samples_count)
      assert_equal(1, @subgroup12b.samples_count)
      assert_equal(4, @group12.samples_count)

      assert_no_changes -> { @group12.reload.samples_count } do
        Samples::TransferJobV2.perform_now(
          @group12,
          @john_doe,
          @sample_transfer_params1[:new_project_id],
          @sample_transfer_params1[:sample_ids]
        )
      end

      assert_equal(0, @subgroup12aa.reload.samples_count)
      assert_equal(1, @subgroup12a.reload.samples_count)
      assert_equal(3, @subgroup12b.reload.samples_count)
    end

    test 'samples count updates after a group sample transfer to a user namespace' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_difference -> { @subgroup12aa.reload.samples_count } => -2,
                        -> { @subgroup12a.reload.samples_count } => -2,
                        -> { @subgroup12b.reload.samples_count } => 0,
                        -> { @group12.reload.samples_count } => -2,
                        -> { @john_doe_project2.reload.samples.size } => 2 do
        Samples::TransferJobV2.perform_now(
          @subgroup12aa,
          @john_doe,
          @john_doe_project2.id,
          [@sample34.id, @sample35.id]
        )
      end
    end

    test 'authorized results in a broadcasted success message and log data with correct responsible id' do
      broadcast_target = SecureRandom.uuid
      sample_ids = [@sample1.id, @sample2.id]

      assert_difference -> { @new_project.reload.samples.count } => 2 do
        Samples::TransferJobV2.perform_now(@current_project.namespace, @john_doe, @new_project.id, sample_ids,
                                           broadcast_target)
      end

      turbo_streams = capture_turbo_stream_broadcasts broadcast_target

      assert_equal @john_doe.id, @new_project.samples.find_by(name: @sample1.name).reload_log_data.responsible_id
      assert_equal @john_doe.id, @new_project.samples.find_by(name: @sample2.name).reload_log_data.responsible_id
      assert_equal 4, turbo_streams.size
      # first 3 turbo streams are for progress bar updates
      turbo_streams.take(3).each do |ts|
        assert_equal 'replace', ts['action']
        assert_equal "#{broadcast_target}-progress-bar", ts['target']
      end
      # last turbo stream is the success message
      assert_equal 'replace', turbo_streams.last['action']
      assert_equal 'transfer_samples_dialog_content', turbo_streams.last['target']
      assert_includes turbo_streams.last.to_html, I18n.t('samples.transfers.create.success')
    end

    test 'authorized results in a broadcasted success message and log dat with interrupt' do
      broadcast_target = SecureRandom.uuid
      sample_ids = [@sample1.id, @sample2.id]

      Samples::TransferJobV2.perform_later(@current_project.namespace, @john_doe, @new_project.id, sample_ids,
                                           broadcast_target)

      assert_difference -> { @new_project.reload.samples.count } => 2 do
        interrupt_job_after_step(Samples::TransferJobV2, :update_counts_and_activities_step) do
          perform_enqueued_jobs(only: Samples::TransferJobV2)
        end
      end

      turbo_streams = capture_turbo_stream_broadcasts broadcast_target

      assert_equal @john_doe.id, @new_project.samples.find_by(name: @sample1.name).reload_log_data.responsible_id
      assert_equal @john_doe.id, @new_project.samples.find_by(name: @sample2.name).reload_log_data.responsible_id
      assert_equal 2, turbo_streams.size # only get the first 2 from the status updates

      # first 3 turbo streams are for progress bar updates
      turbo_streams.take(3).each do |ts|
        assert_equal 'replace', ts['action']
        assert_equal "#{broadcast_target}-progress-bar", ts['target']
      end

      # resume job
      perform_enqueued_jobs(only: Samples::TransferJobV2)

      turbo_streams = capture_turbo_stream_broadcasts broadcast_target
      assert_equal 4, turbo_streams.size # on retry all 4 broadcasts have occurred

      # first 3 turbo streams are for progress bar updates
      turbo_streams.take(3).each do |ts|
        assert_equal 'replace', ts['action']
        assert_equal "#{broadcast_target}-progress-bar", ts['target']
      end
      # last turbo stream is the success message
      assert_equal 'replace', turbo_streams.last['action']
      assert_equal 'transfer_samples_dialog_content', turbo_streams.last['target']
      assert_includes turbo_streams.last.to_html, I18n.t('samples.transfers.create.success')
    end
  end
end

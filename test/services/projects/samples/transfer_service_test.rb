# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class TransferServiceTest < ActiveSupport::TestCase
      def setup # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        @john_doe = users(:john_doe)
        @jane_doe = users(:jane_doe)
        @joan_doe = users(:joan_doe)
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
      end

      test 'transfer project samples with permission' do
        @sample_transfer_params = { new_project_id: @new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
          Projects::Samples::TransferService.new(@current_project.namespace, @john_doe).execute(
            @sample_transfer_params[:new_project_id],
            @sample_transfer_params[:sample_ids]
          )
        end
      end

      test 'transfer project samples with maintainer permission within hierarchy' do
        @sample_transfer_params = { new_project_id: @new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
          Projects::Samples::TransferService.new(@current_project.namespace, @joan_doe).execute(
            @sample_transfer_params[:new_project_id],
            @sample_transfer_params[:sample_ids]
          )
        end
      end

      test 'transfer project samples with maintainer permission but outside of hierarchy' do
        new_project = projects(:project32)

        @sample_transfer_params = { new_project_id: new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_no_changes -> { @sample1.reload.project.id } do
          Projects::Samples::TransferService.new(@current_project.namespace, @joan_doe).execute(
            @sample_transfer_params[:new_project_id],
            @sample_transfer_params[:sample_ids]
          )
        end

        assert @current_project.namespace.errors.full_messages.include?(
          I18n.t('services.samples.transfer.maintainer_transfer_not_allowed')
        )
      end

      test 'transfer project samples without specifying details' do
        assert_empty Projects::Samples::TransferService.new(@current_project.namespace, @john_doe).execute(nil, nil)
      end

      test 'transfer project samples to existing project' do
        @sample_transfer_params = { new_project_id: @current_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_empty Projects::Samples::TransferService.new(@current_project.namespace, @john_doe)
                                                       .execute(@sample_transfer_params[:new_project_id],
                                                                @sample_transfer_params[:sample_ids])
      end

      test 'authorize allowed to transfer project samples with project permission' do
        @sample_transfer_params = { new_project_id: @new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_authorized_to(:transfer_sample?, @current_project,
                             with: ProjectPolicy,
                             context: { user: @john_doe }) do
          Projects::Samples::TransferService.new(@current_project.namespace, @john_doe).execute(
            @sample_transfer_params[:new_project_id],
            @sample_transfer_params[:sample_ids]
          )
        end
      end

      test 'authorize allowed to transfer project samples with target project permission' do
        @sample_transfer_params = { new_project_id: @new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_authorized_to(:transfer_sample_into_project?, @new_project,
                             with: ProjectPolicy,
                             context: { user: @john_doe }) do
          Projects::Samples::TransferService.new(@current_project.namespace, @john_doe).execute(
            @sample_transfer_params[:new_project_id],
            @sample_transfer_params[:sample_ids]
          )
        end
      end

      test 'transfer project samples without permission' do
        @sample_transfer_params = { new_project_id: @new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        exception = assert_raises(ActionPolicy::Unauthorized) do
          Projects::Samples::TransferService.new(@current_project.namespace, @jane_doe).execute(
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

      test 'metadata summary updates after sample transfer' do
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
          Projects::Samples::TransferService.new(@project31.namespace, @john_doe).execute(
            @sample_transfer_params1[:new_project_id],
            @sample_transfer_params1[:sample_ids]
          )
        end

        assert_equal({}, @project31.namespace.reload.metadata_summary)
        assert_equal({}, @subgroup12aa.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12b.reload.metadata_summary)

        assert_no_changes -> { @group12.reload.metadata_summary } do
          Projects::Samples::TransferService.new(@project30.namespace, @john_doe).execute(
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
          Projects::Samples::TransferService.new(@project31.namespace, @john_doe).execute(
            @sample_transfer_params1[:new_project_id],
            @sample_transfer_params1[:sample_ids]
          )
        end

        assert_equal(0, @subgroup12aa.reload.samples_count)
        assert_equal(1, @subgroup12a.reload.samples_count)
        assert_equal(3, @subgroup12b.reload.samples_count)

        assert_no_changes -> { @group12.reload.samples_count } do
          Projects::Samples::TransferService.new(@project30.namespace, @john_doe).execute(
            @sample_transfer_params2[:new_project_id],
            @sample_transfer_params2[:sample_ids]
          )
        end

        assert_equal(0, @subgroup12aa.reload.samples_count)
        assert_equal(4, @subgroup12a.reload.samples_count)
        assert_equal(0, @subgroup12b.reload.samples_count)
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
          Projects::Samples::TransferService.new(@john_doe_project2.namespace, @john_doe).execute(@project31.id,
                                                                                                  [sample24.id])
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
          Projects::Samples::TransferService.new(@project31.namespace, @john_doe).execute(@john_doe_project2.id,
                                                                                          [@sample34.id, @sample35.id])
        end
      end

      test 'samples count updates after a sample transfer between projects in the same user namespace' do
        john_doe_project3 = projects(:john_doe_project3)
        sample24 = samples(:sample24)

        assert_difference -> { @john_doe_project2.reload.samples.size } => -1,
                          -> { john_doe_project3.reload.samples.size } => 1 do
          Projects::Samples::TransferService.new(@john_doe_project2.namespace, @john_doe).execute(john_doe_project3.id,
                                                                                                  [sample24.id])
        end
      end
    end
  end
end

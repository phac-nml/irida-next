# frozen_string_literal: true

require 'test_helper'
module Samples
  class TransferServiceTest < ActiveSupport::TestCase
    def setup # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
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
        Samples::TransferService.new(@current_project.namespace, @john_doe).execute(
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end
    end

    test 'transfer project samples with maintainer permission within hierarchy' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
        Samples::TransferService.new(@current_project.namespace, @joan_doe).execute(
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
        Samples::TransferService.new(@current_project.namespace, @joan_doe).execute(
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end

      assert @current_project.namespace.errors.full_messages.include?(
        I18n.t('services.samples.transfer.maintainer_transfer_not_allowed')
      )
    end

    test 'transfer project samples without specifying details' do
      assert_empty Samples::TransferService.new(@current_project.namespace, @john_doe).execute(nil, nil)
    end

    test 'transfer project samples to existing project' do
      @sample_transfer_params = { new_project_id: @current_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_empty Samples::TransferService.new(@current_project.namespace, @john_doe)
                                           .execute(@sample_transfer_params[:new_project_id],
                                                    @sample_transfer_params[:sample_ids])
    end

    test 'authorize allowed to transfer project samples with project permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_authorized_to(:transfer_sample?, @current_project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Samples::TransferService.new(@current_project.namespace, @john_doe).execute(
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
        Samples::TransferService.new(@current_project.namespace, @john_doe).execute(
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end
    end

    test 'transfer project samples without permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::TransferService.new(@current_project.namespace, @jane_doe).execute(
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
        Samples::TransferService.new(@project31.namespace, @john_doe).execute(
          @sample_transfer_params1[:new_project_id],
          @sample_transfer_params1[:sample_ids]
        )
      end

      assert_equal({}, @project31.namespace.reload.metadata_summary)
      assert_equal({}, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12b.reload.metadata_summary)

      assert_no_changes -> { @group12.reload.metadata_summary } do
        Samples::TransferService.new(@project30.namespace, @john_doe).execute(
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
        Samples::TransferService.new(@project31.namespace, @john_doe).execute(
          @sample_transfer_params1[:new_project_id],
          @sample_transfer_params1[:sample_ids]
        )
      end

      assert_equal(0, @subgroup12aa.reload.samples_count)
      assert_equal(1, @subgroup12a.reload.samples_count)
      assert_equal(3, @subgroup12b.reload.samples_count)

      assert_no_changes -> { @group12.reload.samples_count } do
        Samples::TransferService.new(@project30.namespace, @john_doe).execute(
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
        Samples::TransferService.new(@john_doe_project2.namespace, @john_doe).execute(@project31.id,
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
        Samples::TransferService.new(@project31.namespace, @john_doe).execute(@john_doe_project2.id,
                                                                              [@sample34.id, @sample35.id])
      end
    end

    test 'samples count updates after a sample transfer between projects in the same user namespace' do
      john_doe_project3 = projects(:john_doe_project3)
      sample24 = samples(:sample24)

      assert_difference -> { @john_doe_project2.reload.samples.size } => -1,
                        -> { john_doe_project3.reload.samples.size } => 1 do
        Samples::TransferService.new(@john_doe_project2.namespace, @john_doe).execute(john_doe_project3.id,
                                                                                      [sample24.id])
      end
    end

    test 'transfer group samples with permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
        Samples::TransferService.new(@group, @john_doe).execute(
          @sample_transfer_params[:new_project_id],
          @sample_transfer_params[:sample_ids]
        )
      end
    end

    test 'transfer group samples with maintainer permission within hierarchy' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
        Samples::TransferService.new(@group, @joan_doe).execute(@sample_transfer_params[:new_project_id],
                                                                @sample_transfer_params[:sample_ids])
      end
    end

    test 'transfer group samples with maintainer permission but outside of hierarchy' do
      new_project = projects(:project32)

      @sample_transfer_params = { new_project_id: new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_no_changes -> { @sample1.reload.project.id } do
        Samples::TransferService.new(@group, @joan_doe).execute(
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
        Samples::TransferService.new(@group, @john_doe).execute(
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

      Samples::TransferService.new(@group, @john_doe).execute(
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
        Samples::TransferService.new(@group, @john_doe).execute(
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
      assert_empty Samples::TransferService.new(@group, @john_doe).execute(nil, nil)
    end

    test 'transfer group samples to existing project' do
      @sample_transfer_params = { new_project_id: @current_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_empty Samples::TransferService.new(@group, @john_doe)
                                           .execute(@sample_transfer_params[:new_project_id],
                                                    @sample_transfer_params[:sample_ids])
    end

    test 'authorize allowed to transfer group samples with project permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_authorized_to(:transfer_sample?, @group,
                           with: GroupPolicy,
                           context: { user: @john_doe }) do
        Samples::TransferService.new(@group, @john_doe).execute(@sample_transfer_params[:new_project_id],
                                                                @sample_transfer_params[:sample_ids])
      end
    end

    test 'authorize allowed to transfer group samples with target project permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      assert_authorized_to(:transfer_sample_into_project?, @new_project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Samples::TransferService.new(@group, @john_doe).execute(@sample_transfer_params[:new_project_id],
                                                                @sample_transfer_params[:sample_ids])
      end
    end

    test 'transfer group samples without permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [@sample1.id, @sample2.id] }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::TransferService.new(@group, @ryan_doe).execute(@sample_transfer_params[:new_project_id],
                                                                @sample_transfer_params[:sample_ids])
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
        Samples::TransferService.new(@subgroup12aa, @john_doe).execute(
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
        Samples::TransferService.new(@subgroup12b, @john_doe).execute(
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
        Samples::TransferService.new(@subgroup12aa, @john_doe).execute(
          @sample_transfer_params1[:new_project_id],
          @sample_transfer_params1[:sample_ids]
        )
      end

      assert_equal(0, @subgroup12aa.reload.samples_count)
      assert_equal(1, @subgroup12a.reload.samples_count)
      assert_equal(3, @subgroup12b.reload.samples_count)

      assert_no_changes -> { @group12.reload.samples_count } do
        Samples::TransferService.new(@subgroup12b, @john_doe).execute(
          @sample_transfer_params2[:new_project_id],
          @sample_transfer_params2[:sample_ids]
        )
      end

      assert_equal(0, @subgroup12b.reload.samples_count)
      assert_equal(4, @subgroup12a.reload.samples_count)
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
        Samples::TransferService.new(@subgroup12aa, @john_doe).execute(@john_doe_project2.id,
                                                                       [@sample34.id, @sample35.id])
      end
    end

    # Tests for extracted helper methods
    test 'organize_samples_by_project groups samples by source project' do
      # Create a relation with multiple samples from the same project
      samples = Sample.where(id: [@sample1.id, @sample2.id])

      service = Samples::TransferService.new(@current_project.namespace, @john_doe)
      organized = service.organize_samples_by_project(samples)

      # Verify grouping by project_id
      assert_includes organized.keys, @current_project.id
      # All samples from current_project should be grouped together
      assert_equal 2, organized[@current_project.id].size
      assert_includes organized[@current_project.id], @sample1.id
      assert_includes organized[@current_project.id], @sample2.id
    end

    test 'build_transferred_project_sample_ids returns empty when no samples transferred' do
      service = Samples::TransferService.new(@current_project.namespace, @john_doe)

      project_sample_ids_to_transfer = {
        @current_project.id => [@sample1.id, @sample2.id]
      }
      num_transferred_samples_by_project = {
        @current_project.id => 0
      }

      result = service.build_transferred_project_sample_ids(
        project_sample_ids_to_transfer,
        num_transferred_samples_by_project,
        @new_project,
        Sample.where(id: [@sample1.id, @sample2.id])
      )

      assert_empty result[@current_project.id]
    end

    test 'build_metadata_payload_from_samples extracts metadata keys and counts' do
      # Create samples with specific metadata for this test
      sample_a = Sample.create!(name: "metadata_test_#{SecureRandom.hex}", project: @current_project,
                                metadata: { 'key1' => 'value1', 'key2' => 'value2' })
      sample_b = Sample.create!(name: "metadata_test_#{SecureRandom.hex}", project: @current_project,
                                metadata: { 'key1' => 'value1', 'key3' => 'value3' })

      service = Samples::TransferService.new(@current_project.namespace, @john_doe)
      payload = service.build_metadata_payload_from_samples([sample_a.id, sample_b.id])

      # key1 appears in both samples, key2 and key3 appear in one each
      assert_equal 2, payload['key1']
      assert_equal 1, payload['key2']
      assert_equal 1, payload['key3']

      # Cleanup
      sample_a.destroy
      sample_b.destroy
    end

    test 'namespaces_for_transfer includes project namespace' do
      service = Samples::TransferService.new(@current_project.namespace, @john_doe)
      namespaces = service.namespaces_for_transfer(@current_project.namespace)

      # Should include the project namespace itself
      assert_includes namespaces.pluck(:id), @current_project.namespace.id
    end

    test 'add_transfer_conflict_errors adds error for duplicate sample in target project' do
      # Create duplicate sample in target project
      duplicate = Sample.create!(name: @sample1.name, project: @new_project)

      # Build the expected inputs for the new helper signature:
      # project_sample_ids_to_transfer maps source project => attempted sample ids
      project_sample_ids_to_transfer = { @current_project.id => [@sample1.id] }
      # transferred_project_sample_ids maps source project => actually transferred ids (none in this case)
      transferred_project_sample_ids = { @current_project.id => [] }

      service = Samples::TransferService.new(@current_project.namespace, @john_doe)
      service.add_transfer_conflict_errors(project_sample_ids_to_transfer, transferred_project_sample_ids, @new_project)

      # Should have conflict error
      error_messages = @current_project.namespace.errors.full_messages
      assert(error_messages.any? { |msg| msg.include?(@sample1.name) })

      duplicate.destroy
    end

    test 'add_transfer_conflict_errors adds sample_exists error when name conflict in target project' do
      # Create a conflicting sample in the target project (same name as @sample1)
      conflict = Sample.create!(name: @sample1.name, project: @new_project, puid: SecureRandom.hex)

      project_sample_ids_to_transfer = { @current_project.id => [@sample1.id] }
      transferred_project_sample_ids = { @current_project.id => [] }

      service = Samples::TransferService.new(@current_project.namespace, @john_doe)
      service.add_transfer_conflict_errors(project_sample_ids_to_transfer, transferred_project_sample_ids, @new_project)

      # Expect a sample_exists error mentioning the sample name and puid
      error_messages = @current_project.namespace.errors.full_messages
      expected = I18n.t('services.samples.transfer.sample_exists', sample_name: @sample1.name,
                                                                   sample_puid: @sample1.puid)
      assert(error_messages.any? { |msg| msg.include?(expected) })

      conflict.destroy
    end

    test 'add_transfer_conflict_errors adds samples_not_found when sample belongs to different project' do
      # Create a sample that belongs to a different project than the one we will claim
      other_sample = Sample.create!(name: "mismatch_#{SecureRandom.hex}", project: @project29)

      # Attempt to transfer it from @current_project (wrong source)
      project_sample_ids_to_transfer = { @current_project.id => [other_sample.id] }
      transferred_project_sample_ids = { @current_project.id => [] }

      service = Samples::TransferService.new(@current_project.namespace, @john_doe)
      service.add_transfer_conflict_errors(project_sample_ids_to_transfer, transferred_project_sample_ids, @new_project)

      error_messages = @current_project.namespace.errors.full_messages
      expected = I18n.t('services.samples.transfer.samples_not_found', sample_ids: other_sample.id.to_s)
      assert(error_messages.any? { |msg| msg.include?(expected) })

      other_sample.destroy
    end

    test 'add_transfer_conflict_errors adds target_project_duplicate when sample attempted from target project' do
      # Edge case: attempting to transfer a sample that already lives in the target project
      project_sample_ids_to_transfer = { @new_project.id => [@sample1.id] }
      transferred_project_sample_ids = { @new_project.id => [] }

      service = Samples::TransferService.new(@current_project.namespace, @john_doe)
      service.add_transfer_conflict_errors(project_sample_ids_to_transfer, transferred_project_sample_ids, @new_project)

      error_messages = @current_project.namespace.errors.full_messages
      expected = I18n.t('services.samples.transfer.target_project_duplicate', sample_name: @sample1.name)
      assert(error_messages.any? { |msg| msg.include?(expected) })
    end

    test 'add_transfer_conflict_errors aggregates multiple missing ids into single error' do
      # Create two samples belonging to different projects than attempted
      missing_sample1 = Sample.create!(name: "missing_1_#{SecureRandom.hex}", project: @project29)
      missing_sample2 = Sample.create!(name: "missing_2_#{SecureRandom.hex}", project: @project30)

      # Attempt to transfer both from @current_project (wrong source for both)
      project_sample_ids_to_transfer = { @current_project.id => [missing_sample1.id, missing_sample2.id] }
      transferred_project_sample_ids = { @current_project.id => [] }

      service = Samples::TransferService.new(@current_project.namespace, @john_doe)
      service.add_transfer_conflict_errors(project_sample_ids_to_transfer, transferred_project_sample_ids, @new_project)

      # Both missing ids should be consolidated into a single error message
      error_messages = @current_project.namespace.errors.full_messages
      expected_ids = "#{missing_sample1.id}, #{missing_sample2.id}"
      expected = I18n.t('services.samples.transfer.samples_not_found', sample_ids: expected_ids)
      assert(error_messages.any? { |msg| msg.include?(expected) })

      missing_sample1.destroy
      missing_sample2.destroy
    end
  end
end

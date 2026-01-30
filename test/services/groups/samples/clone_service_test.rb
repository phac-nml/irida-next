# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class CloneServiceTest < ActiveSupport::TestCase
      def setup
        @john_doe = users(:john_doe)
        @group = groups(:group_one)
        @project = projects(:project1)
        @new_project = projects(:project2)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @sample30 = samples(:sample30)
      end

      test 'not clone samples with blank new project id' do
        assert_empty Groups::Samples::CloneService.new(@group, @john_doe).execute('', sample_ids: [@sample1.id])
        assert_equal(@group.errors.full_messages_for(:base).first,
                     I18n.t('services.samples.clone.empty_new_project_id'))
      end

      test 'not clone samples with no sample ids' do
        clone_samples_params = { new_project_id: @new_project.id, sample_ids: [] }
        assert_empty Groups::Samples::CloneService.new(@group, @john_doe).execute(clone_samples_params[:new_project_id],
                                                                                  clone_samples_params[:sample_ids])
        assert_equal(@group.errors.full_messages_for(:base).first,
                     I18n.t('services.samples.clone.empty_sample_ids'))
      end

      test 'not clone samples with not matching sample ids' do
        clone_samples_params = { new_project_id: @new_project.id, sample_ids: ['gid://irida/Sample/not_a_real_id'] }
        assert_empty Groups::Samples::CloneService.new(@group, @john_doe).execute(clone_samples_params[:new_project_id],
                                                                                  clone_samples_params[:sample_ids])
        assert_equal(I18n.t('services.samples.clone.samples_not_found', sample_ids: 'gid://irida/Sample/not_a_real_id'),
                     @group.errors.messages_for(:samples).first)
      end

      test 'authorized to clone samples from source group' do
        clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample1.id, @sample2.id] }
        assert_authorized_to(:clone_sample?, @group,
                             with: GroupPolicy,
                             context: { user: @john_doe }) do
          Groups::Samples::CloneService.new(@group, @john_doe).execute(clone_samples_params[:new_project_id],
                                                                       clone_samples_params[:sample_ids])
        end
      end

      test 'authorized for owner to clone samples into target project' do
        clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample1.id, @sample2.id] }
        assert_authorized_to(:clone_sample_into_project?, @new_project,
                             with: ProjectPolicy,
                             context: { user: @john_doe }) do
          Groups::Samples::CloneService.new(@group, @john_doe).execute(clone_samples_params[:new_project_id],
                                                                       clone_samples_params[:sample_ids])
        end
      end

      test 'authorized for maintainer to clone samples into target project' do
        joan_doe = users(:joan_doe)
        clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample1.id, @sample2.id] }
        assert_authorized_to(:clone_sample_into_project?, @new_project,
                             with: ProjectPolicy,
                             context: { user: joan_doe }) do
          Groups::Samples::CloneService.new(@group, joan_doe).execute(clone_samples_params[:new_project_id],
                                                                      clone_samples_params[:sample_ids])
        end
      end

      test 'unauthorized for non-member to clone samples from source group' do
        jane_doe = users(:jane_doe)
        clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample1.id, @sample2.id] }
        exception = assert_raises(ActionPolicy::Unauthorized) do
          Groups::Samples::CloneService.new(@group, jane_doe).execute(clone_samples_params[:new_project_id],
                                                                      clone_samples_params[:sample_ids])
        end
        assert_equal GroupPolicy, exception.policy
        assert_equal :clone_sample?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.group.clone_sample?',
                            name: @group.name), exception.result.message
      end

      test 'unauthorized for guest to clone samples from source group' do
        ryan_doe = users(:ryan_doe)
        clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample1.id, @sample2.id] }
        exception = assert_raises(ActionPolicy::Unauthorized) do
          Groups::Samples::CloneService.new(@group, ryan_doe).execute(clone_samples_params[:new_project_id],
                                                                      clone_samples_params[:sample_ids])
        end
        assert_equal GroupPolicy, exception.policy
        assert_equal :clone_sample?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.group.clone_sample?',
                            name: @group.name), exception.result.message
      end

      test 'unauthorized for non-member to clone samples into target project' do
        new_project = projects(:project33)
        clone_samples_params = { new_project_id: new_project.id, sample_ids: [@sample1.id, @sample2.id] }
        exception = assert_raises(ActionPolicy::Unauthorized) do
          Groups::Samples::CloneService.new(@group, @john_doe).execute(clone_samples_params[:new_project_id],
                                                                       clone_samples_params[:sample_ids])
        end
        assert_equal ProjectPolicy, exception.policy
        assert_equal :clone_sample_into_project?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.project.clone_sample_into_project?',
                            name: new_project.name), exception.result.message
      end

      test 'unauthorized for guest to clone samples into target project' do
        new_project = projects(:project33)
        james_doe = users(:james_doe)
        clone_samples_params = { new_project_id: new_project.id, sample_ids: [@sample1.id, @sample2.id] }
        exception = assert_raises(ActionPolicy::Unauthorized) do
          Groups::Samples::CloneService.new(@group, james_doe).execute(clone_samples_params[:new_project_id],
                                                                       clone_samples_params[:sample_ids])
        end
        assert_equal ProjectPolicy, exception.policy
        assert_equal :clone_sample_into_project?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.project.clone_sample_into_project?',
                            name: new_project.name), exception.result.message
      end

      test 'clone samples with permission' do
        clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample1.id, @sample2.id] }
        cloned_sample_ids = Groups::Samples::CloneService
                            .new(@group, @john_doe)
                            .execute(
                              clone_samples_params[:new_project_id],
                              clone_samples_params[:sample_ids]
                            )
        cloned_sample_ids.each do |sample_id, clone_id|
          sample = Sample.find_by(id: sample_id)
          clone = Sample.find_by(id: clone_id)
          assert_equal @project.id, sample.project_id
          assert_equal @new_project.id, clone.project_id
          assert_not_equal sample.puid, clone.puid
          assert_equal sample.name, clone.name
          assert_equal sample.description, clone.description
          assert_equal sample.metadata, clone.metadata
          sample_blobs = sample.attachments.map { |attachment| attachment.file.blob }
          clone_blobs = clone.attachments.map { |attachment| attachment.file.blob }
          assert_equal sample_blobs.sort, clone_blobs.sort
        end
      end

      test 'clone samples with metadata' do
        assert_equal({ 'metadatafield1' => 10, 'metadatafield2' => 35 }, @project.namespace.metadata_summary)
        assert_equal({}, @new_project.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 633, 'metadatafield2' => 106 }, @group.metadata_summary)
        clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample30.id] }
        cloned_sample_ids = Groups::Samples::CloneService
                            .new(@group, @john_doe)
                            .execute(
                              clone_samples_params[:new_project_id],
                              clone_samples_params[:sample_ids]
                            )
        cloned_sample_ids.each do |sample_id, clone_id|
          sample = Sample.find_by(id: sample_id)
          clone = Sample.find_by(id: clone_id)
          assert_equal @project.id, sample.project_id
          assert_equal @new_project.id, clone.project_id
          assert_not_equal sample.puid, clone.puid
          assert_equal sample.name, clone.name
          assert_equal sample.description, clone.description
          assert_equal sample.metadata, clone.metadata
          assert_equal sample.metadata_provenance, clone.metadata_provenance
          sample_blobs = sample.attachments.map { |attachment| attachment.file.blob }
          clone_blobs = clone.attachments.map { |attachment| attachment.file.blob }
          assert_equal sample_blobs.sort, clone_blobs.sort
        end
        assert_equal({ 'metadatafield1' => 10, 'metadatafield2' => 35 }, @project.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @new_project.namespace.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 634, 'metadatafield2' => 107 }, @group.reload.metadata_summary)
      end

      test 'not clone samples with same sample name' do
        new_project = projects(:project34)
        clone_samples_params = { new_project_id: new_project.id, sample_ids: [@sample2.id] }
        cloned_sample_ids = Groups::Samples::CloneService
                            .new(@group, @john_doe)
                            .execute(
                              clone_samples_params[:new_project_id],
                              clone_samples_params[:sample_ids]
                            )
        assert_empty cloned_sample_ids
        assert @group.errors.messages_for(:samples).include?(
          I18n.t('services.samples.clone.sample_exists',
                 sample_name: @sample2.name, sample_puid: @sample2.puid)
        )
      end

      test 'samples count updates after cloning sample' do
        # Reference group/projects descendants tree:
        # group12 < subgroup12b (project30 > sample 33)
        #    |
        #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
        group12 = groups(:group_twelve)
        subgroup12a = groups(:subgroup_twelve_a)
        subgroup12b = groups(:subgroup_twelve_b)
        subgroup12aa = groups(:subgroup_twelve_a_a)
        project30 = projects(:project30)
        project31 = projects(:project31)
        sample33 = samples(:sample33)

        assert_difference -> { project30.reload.samples.size } => 0,
                          -> { project31.reload.samples.size } => 1,
                          -> { subgroup12aa.reload.samples_count } => 1,
                          -> { subgroup12a.reload.samples_count } => 1,
                          -> { subgroup12b.reload.samples_count } => 0,
                          -> { group12.reload.samples_count } => 1 do
          Groups::Samples::CloneService.new(group12, @john_doe).execute(project31.id, [sample33.id])
        end
      end

      test 'group clone activities' do
        group = groups(:group_sample_actions)
        user = users(:sample_actions_doe)
        sample69 = samples(:sample69)
        sample70 = samples(:sample70)
        target_project = projects(:projectGroupSampleActions)

        clone_samples_params = { new_project_id: target_project.id, sample_ids: [sample69.id, sample70.id] }
        assert_difference -> { PublicActivity::Activity.count } => 5,
                          -> { Sample.count } => 2 do
          cloned_ids = Groups::Samples::CloneService.new(group, user).execute(
            clone_samples_params[:new_project_id],
            clone_samples_params[:sample_ids]
          )

          sample69_clone_puid = Sample.find(cloned_ids[sample69.id]).puid
          sample70_clone_puid = Sample.find(cloned_ids[sample70.id]).puid

          # verify group activity
          activity = PublicActivity::Activity.where(
            key: 'group.samples.clone'
          ).order(created_at: :desc).first

          assert_equal 'group.samples.clone', activity.key
          assert_equal user, activity.owner
          assert_equal 2, activity.parameters[:cloned_samples_count]
          assert_includes activity.extended_details.details['cloned_samples_data'],
                          { 'clone_puid' => sample69_clone_puid, 'sample_name' => sample69.name,
                            'sample_puid' => sample69.puid,
                            'source_project_name' => sample69.project.name,
                            'source_project_puid' => sample69.project.puid,
                            'target_project_name' => target_project.name,
                            'target_project_puid' => target_project.puid }
          assert_includes activity.extended_details.details['cloned_samples_data'],
                          { 'clone_puid' => sample70_clone_puid, 'sample_name' => sample70.name,
                            'sample_puid' => sample70.puid,
                            'source_project_name' => sample70.project.name,
                            'source_project_puid' => sample70.project.puid,
                            'target_project_name' => target_project.name,
                            'target_project_puid' => target_project.puid }
          assert_equal 2, activity.extended_details.details['cloned_samples_data'].count
          assert_equal 'group_sample_clone',
                       activity.parameters[:action]

          # verify old project activity 1
          activity = PublicActivity::Activity.where(
            key: 'namespaces_project_namespace.samples.clone'
          ).order(created_at: :desc).first

          assert_equal 'namespaces_project_namespace.samples.clone', activity.key
          assert_equal user, activity.owner
          assert_equal 1, activity.parameters[:cloned_samples_count]
          assert_includes activity.extended_details.details['cloned_samples_data'],
                          { 'clone_puid' => sample70_clone_puid, 'sample_name' => sample70.name,
                            'sample_puid' => sample70.puid }
          assert_equal 1, activity.extended_details.details['cloned_samples_data'].count
          assert_equal 'sample_clone', activity.parameters[:action]
          assert_equal target_project.puid, activity.parameters[:target_project_puid]

          # verify old project activity 2
          activity = PublicActivity::Activity.where(
            key: 'namespaces_project_namespace.samples.clone'
          ).order(created_at: :desc).second

          assert_equal 'namespaces_project_namespace.samples.clone', activity.key
          assert_equal user, activity.owner
          assert_equal 1, activity.parameters[:cloned_samples_count]
          assert_includes activity.extended_details.details['cloned_samples_data'],
                          { 'clone_puid' => sample69_clone_puid, 'sample_name' => sample69.name,
                            'sample_puid' => sample69.puid }
          assert_equal 1, activity.extended_details.details['cloned_samples_data'].count
          assert_equal 'sample_clone', activity.parameters[:action]
          assert_equal target_project.puid, activity.parameters[:target_project_puid]

          # verify target project activity 1
          activity = PublicActivity::Activity.where(
            key: 'namespaces_project_namespace.samples.cloned_from'
          ).order(created_at: :desc).first

          assert_equal 'namespaces_project_namespace.samples.cloned_from', activity.key
          assert_equal user, activity.owner
          assert_equal 1, activity.parameters[:cloned_samples_count]
          assert_includes activity.extended_details.details['cloned_samples_data'],
                          { 'clone_puid' => sample70_clone_puid, 'sample_name' => sample70.name,
                            'sample_puid' => sample70.puid }
          assert_equal 1, activity.extended_details.details['cloned_samples_data'].count
          assert_equal 'sample_clone', activity.parameters[:action]
          assert_equal projects(:projectSharedGroupSampleActionsMaintainer).puid,
                       activity.parameters[:source_project_puid]

          # verify target project activity 2
          activity = PublicActivity::Activity.where(
            key: 'namespaces_project_namespace.samples.cloned_from'
          ).order(created_at: :desc).second

          assert_equal 'namespaces_project_namespace.samples.cloned_from', activity.key
          assert_equal user, activity.owner
          assert_equal 1, activity.parameters[:cloned_samples_count]
          assert_includes activity.extended_details.details['cloned_samples_data'],
                          { 'clone_puid' => sample69_clone_puid, 'sample_name' => sample69.name,
                            'sample_puid' => sample69.puid }
          assert_equal 1, activity.extended_details.details['cloned_samples_data'].count
          assert_equal 'sample_clone', activity.parameters[:action]
          assert_equal projects(:projectSharedGroupSampleActionsOwner).puid, activity.parameters[:source_project_puid]
        end
      end

      test 'clone shared group samples with maintainer shared group role' do
        # Group group_sample_actions has access to sample70 via
        # maintainer shared role in Group shared_group_sample_actions_maintainer
        group = groups(:group_sample_actions)
        user = users(:sample_actions_doe)
        sample = samples(:sample70)
        target_project = projects(:projectGroupSampleActions)

        assert_difference -> { Sample.count } => 1,
                          -> { target_project.reload.samples_count } => 1,
                          -> { group.reload.samples_count } => 1 do
          Groups::Samples::CloneService.new(group, user).execute(target_project.id, [sample.id])
        end
      end

      test 'cannot clone shared group samples with analyst shared group role' do
        # Group group_sample_actions has access to sample71 via
        # analyst shared role in Group shared_group_sample_actions_analyst
        group = groups(:group_sample_actions)
        user = users(:sample_actions_doe)
        sample = samples(:sample71)
        target_project = projects(:projectGroupSampleActions)

        assert_difference -> { Sample.count } => 0,
                          -> { target_project.reload.samples_count } => 0,
                          -> { group.reload.samples_count } => 0 do
          Groups::Samples::CloneService.new(group, user).execute(target_project.id, [sample.id])
        end
      end

      test 'clone shared group samples with maintainer shared project role' do
        # Group subgroup_sample_actions has access to sample70 via
        # maintainer shared role in Project projectSharedGroupSampleActionsMaintainer
        group = groups(:subgroup_sample_actions)
        user = users(:subgroup_sample_actions_doe)
        sample = samples(:sample70)
        target_project = projects(:projectSubGroupSampleActions)

        assert_difference -> { Sample.count } => 1,
                          -> { target_project.reload.samples_count } => 1,
                          -> { group.reload.samples_count } => 1 do
          Groups::Samples::CloneService.new(group, user).execute(target_project.id, [sample.id])
        end
      end

      test 'cannot clone shared group samples with analyst shared project role' do
        # Group subgroup_sample_actions has access to sample70 via
        # analyst shared role in Project projectSharedGroupSampleActionsAnalyst
        group = groups(:subgroup_sample_actions)
        user = users(:subgroup_sample_actions_doe)
        sample = samples(:sample71)
        target_project = projects(:projectSubGroupSampleActions)

        assert_difference -> { Sample.count } => 0,
                          -> { target_project.reload.samples_count } => 0,
                          -> { group.reload.samples_count } => 0 do
          Groups::Samples::CloneService.new(group, user).execute(target_project.id, [sample.id])
        end
      end
    end
  end
end

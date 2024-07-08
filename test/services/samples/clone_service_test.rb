# frozen_string_literal: true

require 'test_helper'

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

    test 'not clone samples with empty params' do
      assert_empty Samples::CloneService.new(@project, @john_doe).execute(nil, nil)
      assert_equal(@project.errors.full_messages_for(:base).first,
                   I18n.t('services.samples.clone.empty_new_project_id'))
    end

    test 'not clone samples with no sample ids' do
      clone_samples_params = { new_project_id: @new_project.id, sample_ids: [] }
      assert_empty Samples::CloneService.new(@project, @john_doe).execute(clone_samples_params[:new_project_id],
                                                                          clone_samples_params[:sample_ids])
      assert_equal(@project.errors.full_messages_for(:base).first,
                   I18n.t('services.samples.clone.empty_sample_ids'))
    end

    test 'not clone samples with into same project' do
      clone_samples_params = { new_project_id: @project.id, sample_ids: [@sample1.id, @sample2.id] }
      assert_empty Samples::CloneService.new(@project, @john_doe).execute(clone_samples_params[:new_project_id],
                                                                          clone_samples_params[:sample_ids])
      assert_equal(@project.errors.full_messages_for(:base).first,
                   I18n.t('services.samples.clone.same_project'))
    end

    test 'authorized to clone samples from source project' do
      clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample1.id, @sample2.id] }
      Samples::CloneService.new(@project, @john_doe).execute(clone_samples_params[:new_project_id],
                                                             clone_samples_params[:sample_ids])
      assert_authorized_to(:clone_sample?, @project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Samples::CloneService.new(@project, @john_doe).execute(clone_samples_params[:new_project_id],
                                                               clone_samples_params[:sample_ids])
      end
    end

    test 'authorized for owner to clone samples into target project' do
      clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample1.id, @sample2.id] }
      assert_authorized_to(:clone_sample_into_project?, @new_project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Samples::CloneService.new(@project, @john_doe).execute(clone_samples_params[:new_project_id],
                                                               clone_samples_params[:sample_ids])
      end
    end

    test 'authorized for maintainer to clone samples into target project' do
      joan_doe = users(:joan_doe)
      clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample1.id, @sample2.id] }
      assert_authorized_to(:clone_sample_into_project?, @new_project,
                           with: ProjectPolicy,
                           context: { user: joan_doe }) do
        Samples::CloneService.new(@project, joan_doe).execute(clone_samples_params[:new_project_id],
                                                              clone_samples_params[:sample_ids])
      end
    end

    test 'unauthorized for non-member to clone samples from source project' do
      jane_doe = users(:jane_doe)
      clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample1.id, @sample2.id] }
      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::CloneService.new(@project, jane_doe).execute(clone_samples_params[:new_project_id],
                                                              clone_samples_params[:sample_ids])
      end
      assert_equal ProjectPolicy, exception.policy
      assert_equal :clone_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.clone_sample?',
                          name: @project.name), exception.result.message
    end

    test 'unauthorized for guest to clone samples from source project' do
      ryan_doe = users(:ryan_doe)
      clone_samples_params = { new_project_id: @new_project.id, sample_ids: [@sample1.id, @sample2.id] }
      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::CloneService.new(@project, ryan_doe).execute(clone_samples_params[:new_project_id],
                                                              clone_samples_params[:sample_ids])
      end
      assert_equal ProjectPolicy, exception.policy
      assert_equal :clone_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.clone_sample?',
                          name: @project.name), exception.result.message
    end

    test 'unauthorized for non-member to clone samples into target project' do
      new_project = projects(:project33)
      clone_samples_params = { new_project_id: new_project.id, sample_ids: [@sample1.id, @sample2.id] }
      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::CloneService.new(@project, @john_doe).execute(clone_samples_params[:new_project_id],
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
        Samples::CloneService.new(@project, james_doe).execute(clone_samples_params[:new_project_id],
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
      cloned_sample_ids = Samples::CloneService.new(@project, @john_doe).execute(clone_samples_params[:new_project_id],
                                                                                 clone_samples_params[:sample_ids])
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
      cloned_sample_ids = Samples::CloneService.new(@project, @john_doe).execute(clone_samples_params[:new_project_id],
                                                                                 clone_samples_params[:sample_ids])
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
      cloned_sample_ids = Samples::CloneService.new(@project, @john_doe).execute(clone_samples_params[:new_project_id],
                                                                                 clone_samples_params[:sample_ids])
      assert_empty cloned_sample_ids
      assert @project.errors.messages_for(:sample).include?(
        I18n.t('services.samples.clone.sample_exists',
               sample_name: @sample2.name, sample_puid: @sample2.puid)
      )
    end
  end
end

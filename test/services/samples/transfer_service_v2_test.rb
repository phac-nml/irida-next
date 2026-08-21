# frozen_string_literal: true

require 'test_helper'
module Samples
  class TransferServiceV2Test < ActiveSupport::TestCase
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

    def teardown
      Flipper.disable(:v2_sample_transfer)
    end

    def build_mock_step
      # Minimal step-like object with cursor and advance!
      Struct.new(:cursor) do
        def initialize(cursor = 0)
          @cursor = cursor
        end

        attr_reader :cursor

        def advance!
          @cursor += 1
        end
      end.new(0)
    end

    # Tests for extracted helper methods
    test 'organize_samples_by_project groups samples by source project' do
      # Create a relation with multiple samples from the same project
      samples = Sample.where(id: [@sample1.id, @sample2.id])

      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      organized = service.organize_samples_by_project(samples)

      # Verify grouping by project_id
      assert_includes organized.keys, @current_project.id
      # All samples from current_project should be grouped together
      assert_equal 2, organized[@current_project.id].size
      assert_includes organized[@current_project.id], @sample1.id
      assert_includes organized[@current_project.id], @sample2.id
    end

    test 'build_metadata_payload_from_samples extracts metadata keys and counts' do
      # Create samples with specific metadata for this test
      sample_a = Sample.create!(name: "metadata_test_#{SecureRandom.hex}", project: @current_project,
                                metadata: { 'key1' => 'value1', 'key2' => 'value2' })
      sample_b = Sample.create!(name: "metadata_test_#{SecureRandom.hex}", project: @current_project,
                                metadata: { 'key1' => 'value1', 'key3' => 'value3' })

      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
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
      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      namespaces = service.namespaces_for_transfer(@current_project.namespace)

      # Should include the project namespace itself
      assert_includes namespaces.pluck(:id), @current_project.namespace.id
    end

    test 'add_transfer_conflict_errors adds error for duplicate sample in target project' do
      # Create duplicate sample in target project
      duplicate = Sample.create!(name: @sample1.name, project: @new_project)

      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      service.add_transfer_errors([@sample1.id], [], @new_project.id)

      # Should have conflict error
      error_messages = @current_project.namespace.errors.full_messages
      assert(error_messages.any? { |msg| msg.include?(@sample1.name) })

      duplicate.destroy
    end

    test 'add_transfer_conflict_errors adds sample_exists error when name conflict in target project' do
      # Create a conflicting sample in the target project (same name as @sample1)
      conflict = Sample.create!(name: @sample1.name, project: @new_project, puid: SecureRandom.hex)

      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      service.add_transfer_errors([@sample1.id], [], @new_project.id)

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
      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      service.add_transfer_errors([other_sample.id], [], @new_project.id)

      error_messages = @current_project.namespace.errors.full_messages
      expected = I18n.t('services.samples.transfer.samples_not_found', sample_ids: other_sample.id.to_s)
      assert(error_messages.any? { |msg| msg.include?(expected) })

      other_sample.destroy
    end

    test 'add_transfer_errors adds target_project_duplicate when sample transfer attempted from target project' do
      # Edge case: attempting to transfer a sample that already lives in the target project
      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      service.add_transfer_errors([@sample1.id], [], @sample1.project_id)

      error_messages = @current_project.namespace.errors.full_messages
      expected = I18n.t('services.samples.transfer.target_project_duplicate', sample_name: @sample1.name)
      assert(error_messages.any? { |msg| msg.include?(expected) })
    end

    test 'add_transfer_errors adds sample_exists when valid sample transfer attempted but failed do to generic conflict' do # rubocop:disable Layout/LineLength
      # Edge case: attempting to transfer a sample to a project that already has a sample with that name
      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      service.add_transfer_errors([@sample1.id], [], @new_project.id)

      error_messages = @current_project.namespace.errors.full_messages
      expected = I18n.t('services.samples.transfer.sample_exists', sample_name: @sample1.name, sample_puid: @sample1.puid) # rubocop:disable Layout/LineLength
      assert(error_messages.any? { |msg| msg.include?(expected) })
    end

    test 'add_transfer_conflict_errors aggregates multiple missing ids into single error' do
      # Create two samples belonging to different projects than attempted
      missing_sample1 = Sample.create!(name: "missing_1_#{SecureRandom.hex}", project: @project29)
      missing_sample2 = Sample.create!(name: "missing_2_#{SecureRandom.hex}", project: @project30)

      # Attempt to transfer both from @current_project (wrong source for both)
      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      service.add_transfer_errors([missing_sample1.id, missing_sample2.id], [], @new_project.id)

      # Both missing ids should be consolidated into a single error message
      error_messages = @current_project.namespace.errors.full_messages
      expected_ids = "#{missing_sample1.id}, #{missing_sample2.id}"
      expected = I18n.t('services.samples.transfer.samples_not_found', sample_ids: expected_ids)
      assert(error_messages.any? { |msg| msg.include?(expected) })

      missing_sample1.destroy
      missing_sample2.destroy
    end

    test 'perform_transfer_with_lock moves samples without conflicts' do
      assert_equal @current_project.id, @sample1.project_id

      step = build_mock_step
      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      service.perform_transfer_with_lock(@new_project, { @current_project.id => [@sample1.id] }, SecureRandom.hex, step)

      @sample1.reload
      assert_equal @new_project.id, @sample1.project_id
      assert_not Sample.exists?(id: @sample1.id, project_id: @current_project.id)
    end

    test 'perform_transfer_with_lock with multiple transfers' do
      assert_equal @current_project.id, @sample1.project_id
      assert_equal @current_project.id, @sample2.project_id

      step = build_mock_step
      step2 = build_mock_step
      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      service.perform_transfer_with_lock(
        @new_project, { @current_project.id => [@sample1.id] }, SecureRandom.hex, step
      )
      service.perform_transfer_with_lock(
        @new_project, { @current_project.id => [@sample2.id] }, SecureRandom.hex, step2
      )

      @sample1.reload
      @sample2.reload
      assert_equal @new_project.id, @sample1.project_id
      assert_equal @new_project.id, @sample2.project_id
      assert_not Sample.exists?(id: @sample1.id, project_id: @current_project.id)
      assert_not Sample.exists?(id: @sample2.id, project_id: @current_project.id)
    end

    test 'update_metadata_summary_counts delegates to namespace update' do
      @sample1.metadata = { 'm1' => 'v1' }
      @sample1.save!(validate: false)

      called = false
      old_ns = @current_project.namespace

      old_ns.define_singleton_method(:update_metadata_summary_by_sample_transfer) do |payload, _old_namespaces, _new_namespaces| # rubocop:disable Layout/LineLength
        called = true
        raise unless payload.key?('m1')

        true
      end

      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      service.update_metadata_summary_counts([@sample1.id], @current_project, @new_project)

      assert called
    end

    test 'process_project_transfer_activity creates activities and extended details' do
      data = [{ sample_name: 's1', sample_puid: SecureRandom.hex }]
      group_activity_data = []

      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      service.process_project_transfer_activity(@current_project, @new_project, data, group_activity_data)

      # Check ExtendedDetail created with expected count
      ext = ExtendedDetail.order(:created_at).last
      assert_equal data.size, ext.details['transferred_samples_count']

      # Check activities created on both namespaces
      assert PublicActivity::Activity.exists?(
        trackable_id: @current_project.namespace.id,
        key: 'namespaces_project_namespace.samples.transfer'
      )
      assert PublicActivity::Activity.exists?(
        trackable_id: @new_project.namespace.id,
        key: 'namespaces_project_namespace.samples.transferred_from'
      )
    end

    test 'create_group_activity produces group activity and extended details' do
      group_activity_data = [
        { sample_name: 'g1', sample_puid: SecureRandom.hex, source_project_name: 'src', source_project_id: 1,
          source_project_puid: 'p1', target_project_name: 'tgt', target_project_id: 2, target_project_puid: 'p2' }
      ]

      service = Samples::TransferServiceV2.new(@group, @john_doe)
      service.create_group_activity(group_activity_data)

      assert_equal group_activity_data.size, ExtendedDetail.order(:created_at).last.details['transferred_samples_count']
      assert PublicActivity::Activity.exists?(
        trackable_id: @group.id,
        key: 'group.samples.transfer'
      )
    end

    test 'create_project_activity produces project activity and extended detail' do
      ext_details = ExtendedDetail.create!(
        details: { transferred_samples_count: 1,
                   transferred_samples_data: [{ sample_name: 'p1', sample_puid: SecureRandom.hex }] }
      )

      key = 'namespaces_project_namespace.samples.test_project_activity'
      params = { transferred_samples_count: 1, action: 'sample_transfer' }

      service = Samples::TransferServiceV2.new(@current_project.namespace, @john_doe)
      service.create_project_activity(@current_project.namespace, ext_details.id, key, params)

      activity = PublicActivity::Activity.where(trackable_id: @current_project.namespace.id,
                                                key: key).order(:created_at).last
      assert activity
      assert ActivityExtendedDetail.exists?(activity: activity, extended_detail: ext_details)
    end
  end
end

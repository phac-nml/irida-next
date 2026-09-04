# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class TransferTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:john_doe)
        sign_in @user
        @group = groups(:group_one)
        @project4 = projects(:project4)
        @project2 = projects(:project2)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @sample28 = samples(:sample28)
        @sample29 = samples(:sample29)
        @broadcast_target = "samples_transfer_test_#{SecureRandom.uuid}"
      end

      test 'should get new for group if owner' do
        get new_samples_transfer_path(namespace_id: @group.id, format: :turbo_stream)
        assert_response :success
      end

      test 'should get new for group if maintainer' do
        sign_in users(:joan_doe)

        get new_samples_transfer_path(namespace_id: @group.id, format: :turbo_stream)
        assert_response :success
      end

      test 'should not get new for group if access level less than a maintainer' do
        sign_in users(:ryan_doe)

        get new_samples_transfer_path(namespace_id: @group.id, format: :turbo_stream)
        assert_response :unauthorized
      end

      [[::Samples::TransferJob, false], [::Samples::TransferJobV2, true]].each do |job_class, v2|
        test "should enqueue a #{job_class.name} for group" do
          Flipper.enable(:v2_sample_transfer) if v2

          assert_enqueued_jobs 1, only: job_class do
            post_transfer(sample_ids: [@sample1.id, @sample2.id], destination: @project2)
          end
        ensure
          Flipper.disable(:v2_sample_transfer) if v2
        end
      end

      test 'transfer dialog sample listing' do
        assert_samples_page(@group, 26)
        get new_samples_transfer_path(namespace_id: @group.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_transfer_dialog
        end

        post_list(group_sample_ids)
      end

      test 'transfer dialog with plural description' do
        assert_samples_page(@group, 26)
        get new_samples_transfer_path(namespace_id: @group.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_select '[data-infinite-scroll-plural-description-value=?]',
                        I18n.t('samples.transfers.dialog.description.plural')
        end
      end

      test 'transfer dialog with singular description' do
        assert_samples_page(@group, 26)
        get new_samples_transfer_path(namespace_id: @group.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_select '[data-infinite-scroll-singular-description-value=?]',
                        I18n.t('samples.transfers.dialog.description.singular')
        end
      end

      [[::Samples::TransferJob, false], [::Samples::TransferJobV2, true]].each do |job_class, v2|
        test "transfer samples with #{job_class.name}" do
          Flipper.enable(:v2_sample_transfer) if v2

          assert_samples_page(@group, 26)
          assert_project_samples_page(@project4, 2)
          get new_samples_transfer_path(namespace_id: @group.id, format: :turbo_stream)
          assert_response :success
          assert_select 'turbo-stream[target="samples_dialog"]' do
            assert_transfer_dialog
          end
          post_list(group_sample_ids)

          assert_transfer_enqueued(job_class, sample_ids: [@sample1.id], destination: @project4)
          assert_difference -> { group_sample_scope.where(id: @sample1.id).count } => -1,
                            -> { @project4.samples.count } => 1 do
            perform_enqueued_jobs only: [job_class]
          end

          assert_samples_page(@group, 25)
          assert_select "tbody#samples-table-body tr##{dom_id(@sample1)}", count: 0
          assert_project_samples_page(@project4, 3)
          assert_select "tbody#samples-table-body tr##{dom_id(@sample1)}", count: 1
        ensure
          Flipper.disable(:v2_sample_transfer) if v2
        end
      end

      [
        [::Samples::TransferJob, false, false], [::Samples::TransferJobV2, true, false],
        [::Samples::TransferJob, false, true], [::Samples::TransferJobV2, true, true]
      ].each do |job_class, v2_job, v2_select|
        v2_select_text = v2_select ? 'with v2_select2' : 'with v1_select2'
        test "dialog close button hidden during transfer samples with #{job_class.name} and #{v2_select_text}" do
          Flipper.enable(:v2_sample_transfer) if v2_job
          Flipper.enable(:v2_select2) if v2_select

          get new_samples_transfer_path(namespace_id: @group.id, format: :turbo_stream)
          assert_response :success
          assert_select 'turbo-stream[target="samples_dialog"]' do
            assert_transfer_dialog
          end
          post_transfer
          assert_response :success
          assert_select 'turbo-stream[action="update"][target="transfer_samples_dialog_content"]' do
            assert_select '[role="progressbar"]'
            assert_select 'button.dialog--close', count: 0
          end
        ensure
          Flipper.disable(:v2_sample_transfer) if v2_job
          Flipper.disable(:v2_select2) if v2_select
        end
      end

      [[::Samples::TransferJob, false], [::Samples::TransferJobV2, true]].each do |job_class, v2|
        test "should not transfer samples with session storage cleared for #{job_class.name}" do
          Flipper.enable(:v2_sample_transfer) if v2

          assert_samples_page(@group, 26)
          assert_transfer_enqueued(job_class, sample_ids: [], destination: @project4)
          assert_no_transfer_progress_or_selection(job_class)
        ensure
          Flipper.disable(:v2_sample_transfer) if v2
        end
      end

      [[::Samples::TransferJob, false], [::Samples::TransferJobV2, true]].each do |job_class, v2| # rubocop:disable Style/CombinableLoops
        test "transfer samples with and without same name in destination project for #{job_class.name}" do
          Flipper.enable(:v2_sample_transfer) if v2

          assert_samples_page(@group, 26)
          assert_project_samples_page(@project4, 2)
          get new_samples_transfer_path(namespace_id: @group.id, format: :turbo_stream)
          assert_response :success
          assert_select 'turbo-stream[target="samples_dialog"]' do
            assert_transfer_dialog
          end
          post_list(group_sample_ids)
          assert_transfer_enqueued(job_class, destination: @project4)
          perform_enqueued_jobs only: [job_class]

          assert_samples_page(@group, 2)
          assert_select "tbody#samples-table-body tr##{dom_id(@sample1)}", count: 0
          assert_select "tbody#samples-table-body tr##{dom_id(@sample2)}", count: 0
          assert_select "tbody#samples-table-body tr##{dom_id(@sample28)}", count: 1
          assert_select "tbody#samples-table-body tr##{dom_id(@sample29)}", count: 1
          assert_project_samples_page(@project4, 26, sort: 'puid asc')
          assert_select "tbody#samples-table-body tr##{dom_id(@sample1)}", count: 1
          assert_select "tbody#samples-table-body tr##{dom_id(@sample2)}", count: 1
        ensure
          Flipper.disable(:v2_sample_transfer) if v2
        end
      end

      test 'sample transfer project listing should be empty for maintainer if no other projects in hierarchy' do
        sign_in users(:micha_doe)
        namespace = groups(:group_three)
        get new_samples_transfer_path(namespace_id: namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_transfer_dialog
        end
      end

      test 'empty state of transfer sample project selection' do
        get new_samples_transfer_path(namespace_id: @group.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_select '[data-select2--v1-target="empty"], [data-select2--v2-target="empty"]', count: 1
        end
      end

      private

      def group_sample_ids
        group_sample_scope.ids
      end

      def group_sample_scope
        project_namespaces = Namespace.where(parent_id: @group.self_and_descendant_ids)
        Sample.where(project_id: Project.where(namespace_id: project_namespaces.select(:id)).select(:id))
      end

      def assert_samples_page(group, count)
        get group_samples_path(group)

        assert_response :success
        assert_select 'tbody#samples-table-body tr', count: [count, 20].min
        assert_select 'tfoot', text: /#{I18n.t('samples.table_component.counts.samples')}:\s*#{count}/
      end

      def assert_project_samples_page(project, count, sort: nil)
        namespace = project.namespace.parent || project.namespace
        params = sort ? { q: { sort: } } : {}
        get namespace_project_samples_path(namespace, project), params: params

        assert_response :success
        assert_select 'tbody#samples-table-body tr', count: [count, 20].min
        assert_select 'tfoot', text: /#{I18n.t('samples.table_component.counts.samples')}:\s*#{count}/
      end

      def assert_transfer_dialog
        assert_select 'dialog h1', text: I18n.t('samples.transfers.dialog.title')
        assert_select 'button.dialog--close'
        assert_select 'input.select2-input'
        assert_select 'button', text: I18n.t('samples.transfers.dialog.submit_button')
      end

      def post_list(sample_ids)
        post list_samples_path(format: :turbo_stream),
             params: { page: 1, sample_ids:, list_class: 'sample' },
             as: :turbo_stream

        assert_response :success
        assert_select 'turbo-stream[action="append"][target="list_selections"]' do
          assert_select 'template' do
            sample_ids.first(20).each do |sample_id|
              sample = Sample.find(sample_id)
              assert_select 'p', text: /#{Regexp.escape(sample.name)}/
              assert_select 'p', text: /#{Regexp.escape(sample.puid)}/
            end
          end
        end
      end

      def assert_no_transfer_progress_or_selection(job_class)
        completion_broadcast = assert_no_transfer_progress_and_capture_broadcasts(job_class)

        assert_broadcasts_content(completion_broadcast)
      end

      def assert_no_transfer_progress_and_capture_broadcasts(job_class)
        broadcasts = nil
        assert_difference -> { group_sample_scope.where(id: [@sample1.id, @sample2.id]).count } => 0,
                          -> { @project4.samples.count } => 0 do
          travel 2.seconds do
            broadcasts = capture_turbo_stream_broadcasts(@broadcast_target) do
              perform_enqueued_jobs only: [job_class]
            end
          end
        end

        # return completion_broadcast for further assertions
        broadcasts.find do |message|
          message['action'] == 'replace' && message['target'] == 'transfer_samples_dialog_content'
        end
      end

      def assert_broadcasts_content(completion_broadcast)
        assert_not_nil completion_broadcast

        broadcast = Nokogiri::HTML::DocumentFragment.parse(completion_broadcast.to_html)
        assert_select broadcast, 'turbo-stream[action="replace"][target="transfer_samples_dialog_content"]' do
          assert_select '[role="progressbar"]', count: 0
          assert_select '#list_selections', count: 0
        end
      end

      def assert_transfer_enqueued(job_class, sample_ids: group_sample_ids, destination: @project2)
        assert_enqueued_jobs 1, only: job_class do
          post_transfer(sample_ids:, destination:)
        end
      end

      def post_transfer(sample_ids: group_sample_ids, destination: @project2)
        post samples_transfer_path(namespace_id: @group.id, format: :turbo_stream),
             params: {
               transfer: { new_project_id: destination.id, sample_ids: },
               broadcast_target: @broadcast_target
             },
             as: :turbo_stream
      end
    end
  end
end

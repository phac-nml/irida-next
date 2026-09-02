# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class TransferTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:john_doe)
        sign_in @user
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @sample30 = samples(:sample30)
        @project = projects(:project1)
        @project2 = projects(:project2)
        @namespace = groups(:group_one)
        @broadcast_target = "samples_transfer_test_#{SecureRandom.uuid}"
      end

      test 'should get new for group if owner' do
        get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
      end

      test 'should get new for group if maintainer' do
        user = users(:joan_doe)
        login_as user

        get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
      end

      test 'should not get new for group if access level less than a maintainer' do
        user = users(:ryan_doe)
        login_as user

        get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :unauthorized
      end

      test 'should enqueue a Samples::TransferJob for group' do
        assert_enqueued_jobs 1, only: ::Samples::TransferJob do
          post_transfer(sample_ids: [@sample1.id, @sample2.id], destination: @project2)
        end
      end

      test 'should enqueue a Samples::TransferJobV2 for group' do
        Flipper.enable(:v2_sample_transfer)

        assert_enqueued_jobs 1, only: ::Samples::TransferJobV2 do
          post_transfer(sample_ids: [@sample1.id, @sample2.id], destination: @project2)
        end
      ensure
        Flipper.disable(:v2_sample_transfer)
      end

      test 'should get new for project if owner' do
        get new_samples_transfer_path(namespace_id: @project.namespace.id, format: :turbo_stream)
        assert_response :success
      end

      test 'should not get new for project if non-owner' do
        user = users(:micha_doe)
        login_as user

        get new_samples_transfer_path(namespace_id: @project.namespace.id, format: :turbo_stream)
        assert_response :unauthorized
      end

      test 'should enqueue a Samples::TransferJob for project' do
        assert_enqueued_jobs 1, only: ::Samples::TransferJob do
          post samples_transfer_path(namespace_id: @project.namespace.id, format: :turbo_stream),
               params: {
                 transfer: {
                   new_project_id: @project2.id,
                   sample_ids: [@sample1.id, @sample2.id]
                 },
                 broadcast_target: 'a_broadcast_target'
               }
        end
      end

      test 'should enqueue a Samples::TransferJobV2 for project' do
        Flipper.enable(:v2_sample_transfer)

        assert_enqueued_jobs 1, only: ::Samples::TransferJobV2 do
          post samples_transfer_path(namespace_id: @project.namespace.id, format: :turbo_stream),
               params: {
                 transfer: {
                   new_project_id: @project2.id,
                   sample_ids: [@sample1.id, @sample2.id]
                 },
                 broadcast_target: 'a_broadcast_target'
               }
        end
      ensure
        Flipper.disable(:v2_sample_transfer)
      end

      test 'transfer dialog sample listing' do
        assert_samples_page(@project, 3)
        get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[action="update"][target="samples_dialog"]' do
          assert_transfer_dialog
        end

        post list_samples_path(format: :turbo_stream),
             params: { page: 1, sample_ids: @project.samples.ids, list_class: 'sample' },
             as: :turbo_stream
        assert_response :success
        assert_select 'turbo-stream[action="append"][target="list_selections"]' do
          assert_select 'template' do
            @project.samples.each do |sample|
              assert_select 'p', text: /#{Regexp.escape(sample.name)}/
              assert_select 'p', text: /#{Regexp.escape(sample.puid)}/
            end
          end
        end
      end

      test 'transfer dialog with plural description' do
        assert_samples_page(@project, 3)
        get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_transfer_dialog
          assert_select '[data-infinite-scroll-plural-description-value=?]',
                        I18n.t('samples.transfers.dialog.description.plural')
        end
      end

      test 'transfer dialog with singular description' do
        assert_samples_page(@project, 3)
        get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_transfer_dialog
          assert_select '[data-infinite-scroll-singular-description-value=?]',
                        I18n.t('samples.transfers.dialog.description.singular')
        end
      end

      test 'transfer samples' do
        assert_samples_page(@project2, 20)
        assert_samples_page(@project, 3)
        get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_transfer_dialog
        end
        post_list(@project.samples.ids)

        assert_transfer_enqueued(::Samples::TransferJob)
        assert_difference(-> { @project2.samples.count }, 3) do
          perform_enqueued_jobs only: [::Samples::TransferJob]
        end

        assert_empty @project.samples.where(id: [@sample1.id, @sample2.id, @sample30.id])
        assert_samples_page(@project2, 23)
        [@sample1, @sample2, @sample30].each do |sample|
          assert_select "tbody#samples-table-body tr##{dom_id(sample)}", count: 1
        end
      end

      test 'dialog close button hidden during transfer samples' do
        assert_samples_page(@project, 3)
        get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
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
      end

      test 'should not transfer samples with session storage cleared' do
        assert_samples_page(@project, 3)
        assert_transfer_enqueued(::Samples::TransferJob, sample_ids: [])
        assert_no_transfer_progress_or_selection(::Samples::TransferJob)
      end

      test 'transfer samples with and without same name in destination project' do
        destination = projects(:project25)
        assert_samples_page(destination, 2)
        assert_samples_page(@project, 3)
        assert_transfer_enqueued(::Samples::TransferJob, destination:)
        perform_enqueued_jobs only: [::Samples::TransferJob]

        assert_not @project.samples.exists?(@sample1.id)
        assert_not @project.samples.exists?(@sample2.id)
        assert @project.samples.exists?(@sample30.id)
        assert destination.samples.exists?(@sample1.id)
        assert destination.samples.exists?(@sample2.id)
        assert_samples_page(destination, 4)
        assert_select "tbody#samples-table-body tr##{dom_id(@sample1)}", count: 1
        assert_select "tbody#samples-table-body tr##{dom_id(@sample2)}", count: 1
        assert_select "tbody#samples-table-body tr##{dom_id(@sample30)}", count: 0
      end

      test 'updating sample selection during transfer samples' do
        assert_samples_page(@project2, 20)
        assert_samples_page(@project, 3)
        assert_transfer_enqueued(::Samples::TransferJob, sample_ids: [@sample1.id])
        assert_difference -> { @project.samples.count } => -1,
                          -> { @project2.samples.count } => 1 do
          perform_enqueued_jobs only: [::Samples::TransferJob]
        end

        assert_not @project.samples.exists?(@sample1.id)
        assert_samples_page(@project2, 21)
        assert_select 'tbody#samples-table-body input[name="sample_ids[]"][checked]', count: 0
      end

      test 'transfer samples v2' do
        Flipper.enable(:v2_sample_transfer)
        assert_samples_page(@project2, 20)
        assert_samples_page(@project, 3)
        assert_transfer_enqueued(::Samples::TransferJobV2)
        assert_difference(-> { @project2.samples.count }, 3) do
          perform_enqueued_jobs only: [::Samples::TransferJobV2]
        end

        assert_empty @project.samples.where(id: [@sample1.id, @sample2.id, @sample30.id])
        assert_samples_page(@project2, 23)
        [@sample1, @sample2, @sample30].each do |sample|
          assert_select "tbody#samples-table-body tr##{dom_id(sample)}", count: 1
        end
      ensure
        Flipper.disable(:v2_sample_transfer)
      end

      test 'dialog close button hidden during transfer samples v2' do
        Flipper.enable(:v2_sample_transfer)
        assert_samples_page(@project, 3)
        get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_transfer_dialog
        end
        post_transfer
        assert_response :success
        assert_select 'turbo-stream[action="update"][target="transfer_samples_dialog_content"]' do
          assert_select 'button.dialog--close', count: 0
        end
      ensure
        Flipper.disable(:v2_sample_transfer)
      end

      test 'should not transfer samples with session storage cleared v2' do
        Flipper.enable(:v2_sample_transfer)
        assert_samples_page(@project, 3)
        assert_transfer_enqueued(::Samples::TransferJobV2, sample_ids: [])
        assert_no_transfer_progress_or_selection(::Samples::TransferJobV2)
      ensure
        Flipper.disable(:v2_sample_transfer)
      end

      test 'transfer samples with and without same name in destination project v2' do
        Flipper.enable(:v2_sample_transfer)
        destination = projects(:project25)
        assert_samples_page(destination, 2)
        assert_samples_page(@project, 3)
        assert_transfer_enqueued(::Samples::TransferJobV2, destination:)
        perform_enqueued_jobs only: [::Samples::TransferJobV2]

        assert_not @project.samples.exists?(@sample1.id)
        assert_not @project.samples.exists?(@sample2.id)
        assert @project.samples.exists?(@sample30.id)
        assert destination.samples.exists?(@sample1.id)
        assert destination.samples.exists?(@sample2.id)
        assert_samples_page(destination, 4)
        assert_select "tbody#samples-table-body tr##{dom_id(@sample1)}", count: 1
        assert_select "tbody#samples-table-body tr##{dom_id(@sample2)}", count: 1
        assert_select "tbody#samples-table-body tr##{dom_id(@sample30)}", count: 0
      ensure
        Flipper.disable(:v2_sample_transfer)
      end

      test 'updating sample selection during transfer samples v2' do
        Flipper.enable(:v2_sample_transfer)
        assert_samples_page(@project2, 20)
        assert_samples_page(@project, 3)
        assert_transfer_enqueued(::Samples::TransferJobV2, sample_ids: [@sample1.id])
        assert_difference -> { @project.samples.count } => -1,
                          -> { @project2.samples.count } => 1 do
          perform_enqueued_jobs only: [::Samples::TransferJobV2]
        end

        assert_not @project.samples.exists?(@sample1.id)
        assert_samples_page(@project2, 21)
        assert_select 'tbody#samples-table-body input[name="sample_ids[]"][checked]', count: 0
      ensure
        Flipper.disable(:v2_sample_transfer)
      end

      test 'sample transfer button should not be available for maintainer of a user namespace project' do
        login_as users(:micha_doe)
        namespace = projects(:projectUser31).namespace
        get new_samples_transfer_path(namespace_id: namespace.id, format: :turbo_stream)
        assert_response :unauthorized
      end

      test 'sample transfer project listing should be empty for maintainer if no other projects in hierarchy' do
        login_as users(:user28)
        namespace = projects(:projectHotel).namespace
        get new_samples_transfer_path(namespace_id: namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_select "input[placeholder='#{I18n.t('samples.transfers.dialog.no_available_projects')}'][disabled]"
        end
      end

      test 'empty state of transfer sample project selection' do
        get new_samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_select '[data-select2--v1-target="empty"], [data-select2--v2-target="empty"]', count: 1
        end
      end

      private

      def assert_samples_page(project, count)
        namespace = project.namespace.parent || project.namespace
        get namespace_project_samples_path(namespace, project)

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
            sample_ids.each do |sample_id|
              sample = Sample.find(sample_id)
              assert_select 'p', text: /#{Regexp.escape(sample.name)}/
              assert_select 'p', text: /#{Regexp.escape(sample.puid)}/
            end
          end
        end
      end

      def assert_no_transfer_progress_or_selection(job_class) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        broadcasts = nil
        assert_difference -> { @project.samples.where(id: [@sample1.id, @sample2.id, @sample30.id]).count } => 0,
                          -> { @project2.samples.count } => 0 do
          travel 2.seconds do
            broadcasts = capture_turbo_stream_broadcasts(@broadcast_target) do
              perform_enqueued_jobs only: [job_class]
            end
          end
        end

        completion_broadcast = broadcasts.find do |message|
          message['action'] == 'replace' && message['target'] == 'transfer_samples_dialog_content'
        end
        assert_not_nil completion_broadcast

        broadcast = Nokogiri::HTML::DocumentFragment.parse(completion_broadcast.to_html)
        assert_select broadcast, 'turbo-stream[action="replace"][target="transfer_samples_dialog_content"]' do
          assert_select '[role="progressbar"]', count: 0
          assert_select '#list_selections', count: 0
        end
      end

      def assert_transfer_enqueued(job_class, sample_ids: @project.samples.ids, destination: @project2)
        assert_enqueued_jobs 1, only: job_class do
          post_transfer(sample_ids:, destination:)
        end
      end

      def post_transfer(sample_ids: @project.samples.ids, destination: @project2)
        post samples_transfer_path(namespace_id: @namespace.id, format: :turbo_stream),
             params: {
               transfer: { new_project_id: destination.id, sample_ids: },
               broadcast_target: @broadcast_target
             },
             as: :turbo_stream
      end
    end
  end
end

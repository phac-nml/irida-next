# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class CloneTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:john_doe)
        sign_in @user
        @namespace = groups(:group_one)
        @project = projects(:project1)
        @project2 = projects(:project2)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
        @sample30 = samples(:sample30)
        @broadcast_target = "samples_clone_test_#{SecureRandom.uuid}"
      end

      test 'new with proper authorization from group' do
        get new_samples_clone_path, params: { namespace_id: @namespace.id }, as: :turbo_stream
        assert_response :success
      end

      test 'new without proper authorization from group' do
        sign_in users(:ryan_doe)
        get new_samples_clone_path, params: { namespace_id: @namespace.id }, as: :turbo_stream
        assert_response :unauthorized
      end

      test 'should enqueue a Samples::CloneJob from group' do
        assert_enqueued_jobs 1, only: ::Samples::CloneJob do
          post_clone(namespace_id: @namespace.id, sample_ids: [@sample1.id, @sample2.id],
                     destination: @project2)
        end
      end

      test 'clone dialog sample listing' do
        assert_samples_page(@namespace, 26)
        get new_samples_clone_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[action="update"][target="samples_dialog"]' do
          assert_clone_dialog
        end

        post_list([@sample1.id, @sample2.id])
      end

      test 'clone dialog with plural description' do
        assert_samples_page(@namespace, 26)
        get new_samples_clone_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_clone_dialog
          assert_select '[data-infinite-scroll-plural-description-value=?]',
                        I18n.t('samples.clones.dialog.description.plural')
        end
      end

      test 'clone dialog with singular description' do
        assert_samples_page(@namespace, 26)
        get new_samples_clone_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_clone_dialog
          assert_select '[data-infinite-scroll-singular-description-value=?]',
                        I18n.t('samples.clones.dialog.description.singular')
        end
      end

      test 'should clone samples' do
        assert_project_samples_page(@project2, 20)
        assert_samples_page(@namespace, 26)
        get new_samples_clone_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_clone_dialog
        end
        post_list([@sample1.id, @sample2.id])

        assert_clone_enqueued sample_ids: [@sample1.id, @sample2.id]
        assert_difference -> { @project2.samples.count } => 2 do
          perform_enqueued_jobs only: [::Samples::CloneJob], at: 2.seconds.from_now
        end

        assert_samples_page(@namespace, 28)
        assert_project_samples_page(@project2, 22)
        [@sample1, @sample2].each do |sample|
          assert_select 'tbody#samples-table-body tr', text: /#{Regexp.escape(sample.name)}/, count: 1
        end
      end

      test 'dialog close button hidden while cloning samples' do
        assert_samples_page(@namespace, 26)
        get new_samples_clone_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_clone_dialog
        end
        post_clone
        assert_response :success
        assert_select 'turbo-stream[action="update"][target="clone_samples_dialog_content"]' do
          assert_select '[role="progressbar"]'
          assert_select 'button.dialog--close', count: 0
        end
      end

      test 'should not clone samples with session storage cleared' do
        assert_samples_page(@namespace, 26)
        assert_clone_enqueued sample_ids: []
        assert_no_clone_progress_or_selection
      end

      test 'updating sample selection during sample cloning' do
        assert_project_samples_page(@project2, 20)
        assert_samples_page(@namespace, 26)
        assert_clone_enqueued sample_ids: [@sample1.id]

        assert_difference -> { @project2.samples.count } => 1 do
          perform_enqueued_jobs only: [::Samples::CloneJob]
        end

        assert group_sample_scope.exists?(@sample1.id)
        assert_project_samples_page(@project2, 21)
        assert_select 'tbody#samples-table-body input[name="sample_ids[]"][checked]', count: 0
      end

      test 'should not clone some samples' do
        destination = projects(:project25)
        namespace = groups(:subgroup1)
        assert_project_samples_page(destination, 2, namespace:)
        assert_samples_page(@namespace, 26)
        get new_samples_clone_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_clone_dialog
        end

        post_list([@sample1.id, @sample2.id, @sample30.id])
        assert_clone_enqueued sample_ids: [@sample1.id, @sample2.id, @sample30.id], destination: destination

        broadcasts = capture_turbo_stream_broadcasts(@broadcast_target) do
          perform_enqueued_jobs only: [::Samples::CloneJob]
        end

        assert destination.samples.exists?(name: @sample1.name)
        assert destination.samples.exists?(name: @sample2.name)
        assert destination.samples.exists?(name: @sample30.name)
        assert_clone_error_broadcast(broadcasts, @sample30)
        assert_project_samples_page(destination, 4, namespace:)
        post_list([@sample1.id, @sample2.id, @sample30.id])
      end

      test 'empty state of destination project selection for sample cloning' do
        get new_samples_clone_path(namespace_id: @namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_select '[data-select2--v1-target="empty"], [data-select2--v2-target="empty"]', count: 1
        end
      end

      test 'sample clone group listing should be empty for maintainer if no other groups in hierarchy' do
        sign_in users(:clone_test_maintainer_one)
        namespace = groups(:clone_test_group_one)
        get new_samples_clone_path(namespace_id: namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_select "input[placeholder='#{I18n.t('samples.clones.dialog.no_available_projects')}'][disabled]"
        end
      end

      test 'no available destination groups to clone samples' do
        sign_in users(:clone_test_maintainer_two)
        namespace = groups(:clone_test_group_two)
        get new_samples_clone_path(namespace_id: namespace.id, format: :turbo_stream)
        assert_response :success
        assert_select 'turbo-stream[target="samples_dialog"]' do
          assert_select "input[placeholder='#{I18n.t('samples.clones.dialog.no_available_projects')}'][disabled]"
        end
      end

      private

      def group_sample_scope
        project_namespaces = Namespace.where(parent_id: @namespace.self_and_descendant_ids)
        Sample.where(project_id: Project.where(namespace_id: project_namespaces.select(:id)).select(:id))
      end

      def group_sample_ids
        group_sample_scope.ids
      end

      def assert_samples_page(group, count)
        get group_samples_path(group)

        assert_response :success
        assert_select 'tbody#samples-table-body tr', count: [count, 20].min
        assert_select 'tfoot', text: /#{I18n.t('samples.table_component.counts.samples')}:\s*#{count}/
      end

      def assert_project_samples_page(project, count, namespace: nil)
        namespace ||= project.namespace.parent || project.namespace
        get namespace_project_samples_path(namespace, project)

        assert_response :success
        assert_select 'tbody#samples-table-body tr', count: [count, 20].min
        assert_select 'tfoot', text: /#{I18n.t('samples.table_component.counts.samples')}:\s*#{count}/
      end

      def assert_clone_dialog
        assert_select 'dialog h1', text: I18n.t('samples.clones.dialog.title')
        assert_select 'button.dialog--close'
        assert_select 'input.select2-input'
        assert_select 'button', text: I18n.t('samples.clones.dialog.submit_button')
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

      def assert_clone_enqueued(sample_ids: group_sample_ids, destination: @project2)
        assert_enqueued_jobs 1, only: ::Samples::CloneJob do
          post_clone(sample_ids:, destination:)
        end
      end

      def assert_no_clone_progress_or_selection
        completion_broadcast = assert_no_clone_progress_and_capture_broadcasts

        assert_clone_broadcasts_content(completion_broadcast)
      end

      def assert_no_clone_progress_and_capture_broadcasts
        broadcasts = nil
        assert_difference -> { group_sample_scope.where(id: [@sample1.id, @sample2.id]).count } => 0,
                          -> { @project2.samples.count } => 0 do
          travel 2.seconds do
            broadcasts = capture_turbo_stream_broadcasts(@broadcast_target) do
              perform_enqueued_jobs only: [::Samples::CloneJob]
            end
          end
        end

        broadcasts.find do |message|
          message['action'] == 'replace' && message['target'] == 'clone_samples_dialog_content'
        end
      end

      def assert_clone_broadcasts_content(completion_broadcast)
        assert_not_nil completion_broadcast

        broadcast = Nokogiri::HTML::DocumentFragment.parse(completion_broadcast.to_html)
        assert_select broadcast, 'turbo-stream[action="replace"][target="clone_samples_dialog_content"]' do
          assert_select '[role="progressbar"]', count: 0
          assert_select '#list_selections', count: 0
        end
      end

      def assert_clone_error_broadcast(broadcasts, sample)
        error_broadcast = broadcasts.find do |message|
          message['action'] == 'replace' && message['target'] == 'clone_samples_dialog_content'
        end
        assert_not_nil error_broadcast

        broadcast_text = Nokogiri::HTML::DocumentFragment.parse(error_broadcast.to_html).text
        assert_includes broadcast_text, I18n.t('samples.clones.create.error')
        assert_includes broadcast_text, sample.puid
        assert_includes broadcast_text, sample.name
      end

      def post_clone(namespace_id: @namespace.id, sample_ids: group_sample_ids, destination: @project2)
        post samples_clone_path,
             params: {
               namespace_id:,
               clone: {
                 new_project_id: destination.id,
                 sample_ids:
               },
               broadcast_target: @broadcast_target
             }, as: :turbo_stream
      end
    end
  end
end

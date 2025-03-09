# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    class ClonesControllerTest < ActionDispatch::IntegrationTest
      setup do
        sign_in users(:john_doe)
        @namespace = groups(:group_one)
        @project = projects(:project1)
        @new_project = projects(:project2)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
      end

      test 'should enqueue a Samples::CloneJob' do
        assert_enqueued_jobs 1, only: ::Samples::CloneJob do
          post namespace_project_samples_clone_path(@namespace, @project, format: :turbo_stream),
               params: {
                 clone: {
                   new_project_id: @new_project.id,
                   sample_ids: [@sample1.id, @sample2.id]
                 },
                 broadcast_target: 'a_broadcast_target'
               }
        end
      end
    end
  end
end

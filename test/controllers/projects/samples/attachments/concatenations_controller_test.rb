# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    module Attachments
      class ConcatenationControllerTest < ActionDispatch::IntegrationTest
        setup do
          sign_in users(:john_doe)
          @sample1 = samples(:sample1)
          @project1 = projects(:project1)
          @namespace = groups(:group_one)
          @attachment1 = attachments(:attachment1)
          @attachment2 = attachments(:attachment2)
        end

        test 'should get new for a member with role >= maintainer' do
          get new_namespace_project_sample_attachments_concatenation_path(@namespace, @project1, @sample1,
                                                                          format: :turbo_stream)
          assert_response :success
        end

        test 'should not get new if not a member' do
          user = users(:micha_doe)
          login_as user

          get new_namespace_project_sample_attachments_concatenation_path(@namespace, @project1, @sample1,
                                                                          format: :turbo_stream)
          assert_response :unauthorized
        end

        test 'should create sample attachments concatenation for a member with role >= maintainer' do
          post namespace_project_sample_attachments_concatenation_path(@namespace, @project1, @sample1,
                                                                       format: :turbo_stream),
               params: {
                 basename: 'blah',
                 attachment_ids: [@attachment1.id, @attachment2.id]
               }

          assert_response :success
        end

        test 'should not create sample attachments concatenation for a non member' do
          user = users(:micha_doe)
          login_as user

          post namespace_project_sample_attachments_concatenation_path(@namespace, @project1, @sample1,
                                                                       format: :turbo_stream)
          assert_response :unauthorized
        end
      end
    end
  end
end

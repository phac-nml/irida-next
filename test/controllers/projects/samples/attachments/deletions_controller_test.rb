# frozen_string_literal: true

require 'test_helper'

module Projects
  module Samples
    module Attachments
      class DeletionsControllerTest < ActionDispatch::IntegrationTest
        setup do
          sign_in users(:jeff_doe)
          @sample1 = samples(:sampleA)
          @sample2 = samples(:sampleB)
          @project1 = projects(:projectA)
          @namespace = namespaces_user_namespaces(:jeff_doe_namespace)
          @attachment1 = attachments(:attachmentA)
          @attachment2 = attachments(:attachmentB)
          @attachment3 = attachments(:attachmentPEFWD1)
          @attachment4 = attachments(:attachmentPEREV1)
          @attachment5 = attachments(:attachmentPEFWD2)
          @attachment6 = attachments(:attachmentPEREV2)
        end

        test 'should get new for a member with role >= maintainer' do
          get new_namespace_project_sample_attachments_deletion_path(@namespace, @project1, @sample1,
                                                                     format: :turbo_stream)
          assert_response :success
        end

        test 'should not get new if not a member' do
          user = users(:micha_doe)
          login_as user

          get new_namespace_project_sample_attachments_deletion_path(@namespace, @project1, @sample1,
                                                                     format: :turbo_stream)
          assert_response :unauthorized
        end

        test 'should delete attachments for a member with role == owner' do
          delete namespace_project_sample_attachments_deletion_path(@namespace, @project1, @sample1,
                                                                    format: :turbo_stream),
                 params: {
                   deletion: {
                     attachment_ids: { '0' => @attachment1.id, '1' => @attachment2.id }
                   }
                 }

          assert_response :success
        end

        test 'should delete paired attachments' do
          delete namespace_project_sample_attachments_deletion_path(@namespace, @project1, @sample2,
                                                                    format: :turbo_stream),
                 params: {
                   deletion: {
                     attachment_ids: { '0' => [@attachment3.id, @attachment4.id],
                                       '1' => [@attachment5.id, @attachment6.id] }
                   }
                 }

          assert_response :success
        end

        test 'should get multi_status when only partial attachments are deleted' do
          delete namespace_project_sample_attachments_deletion_path(@namespace, @project1, @sample2,
                                                                    format: :turbo_stream),
                 params: {
                   deletion: {
                     attachment_ids: { '0' => @attachment1.id,
                                       '1' => [@attachment5.id, @attachment6.id] }
                   }
                 }

          assert_response :multi_status
        end

        test 'should get unprocessable_content when no attachments are deleted' do
          delete namespace_project_sample_attachments_deletion_path(@namespace, @project1, @sample2,
                                                                    format: :turbo_stream),
                 params: {
                   deletion: {
                     attachment_ids: { '0' => @attachment1.id, '1' => @attachment2.id }
                   }
                 }

          assert_response :unprocessable_content
        end

        test 'should not delete attachments with role <= owner' do
          user = users(:micha_doe)
          login_as user

          delete namespace_project_sample_attachments_deletion_path(@namespace, @project1, @sample1,
                                                                    format: :turbo_stream)
          assert_response :unauthorized
        end
      end
    end
  end
end

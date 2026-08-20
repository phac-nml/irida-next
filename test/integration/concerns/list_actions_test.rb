# frozen_string_literal: true

require 'test_helper'

module Concerns
  class ListActionsTest < ActionDispatch::IntegrationTest
    test 'should list attachments' do
      sign_in users(:jeff_doe)
      project = projects(:projectA)
      sample = samples(:sampleC)
      namespace = namespaces_user_namespaces(:jeff_doe_namespace)

      pe_fwd_attachment = attachments(:attachmentPEFWD4)
      pe_rev_attachment = attachments(:attachmentPEREV4)
      non_pe_attachment = attachments(:attachmentG)
      post list_namespace_project_sample_attachments_path(namespace, project, sample, format: :turbo_stream), params: {
        page: 1,
        attachment_ids: ["[#{pe_fwd_attachment.id}, #{pe_rev_attachment.id}]", non_pe_attachment.id],
        list_class: 'attachment'
      }
      assert_response :success
    end
  end
end

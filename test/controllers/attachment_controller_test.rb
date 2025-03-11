# frozen_string_literal: true

require 'test_helper'

# Tests for the AttachmentController
#
# Note: These tests focus on the error handling and authorization aspects of the controller.
# Testing the preview functionality would require setting up Active Storage test fixtures
# with actual file content, which is complex in a test environment. The preview functionality
# is better tested through system/integration tests where actual files can be uploaded.
class AttachmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # Enable the attachments_preview feature flag for testing
    Flipper.enable(:attachments_preview)

    # Sign in as a user with access to attachments
    sign_in users(:john_doe)

    # Set up common test data
    @attachment = attachments(:attachment1) # fastq format
  end

  teardown do
    # Disable the feature flag after tests
    Flipper.disable(:attachments_preview)
  end

  test 'should redirect with alert when attachment not found' do
    # Mock the set_attachment method to return nil
    AttachmentsController.class_eval do
      alias_method :original_set_attachment, :set_attachment
      alias_method :original_set_context_crumbs, :set_context_crumbs

      def set_attachment
        @attachment = nil
      end

      def set_context_crumbs
        @context_crumbs = []
      end
    end

    get attachment_path(id: 'non-existent-id')

    # Restore the original methods
    AttachmentsController.class_eval do
      alias_method :set_attachment, :original_set_attachment
      alias_method :set_context_crumbs, :original_set_context_crumbs
      remove_method :original_set_attachment
      remove_method :original_set_context_crumbs
    end

    assert_redirected_to root_path
    assert_equal I18n.t('attachment.show.file_not_found'), flash[:alert]
  end

  test 'should redirect when attachments_preview feature is disabled' do
    # Disable the feature flag
    Flipper.disable(:attachments_preview)

    get attachment_path(@attachment)
    assert_redirected_to root_path

    # Re-enable for other tests
    Flipper.enable(:attachments_preview)
  end

  test 'should handle unauthorized access' do
    sign_out users(:john_doe)

    get attachment_path(@attachment)
    assert_redirected_to new_user_session_path
  end
end

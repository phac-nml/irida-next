# frozen_string_literal: true

require 'test_helper'

class AttachmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # Sign in as a user with access to attachments
    sign_in users(:john_doe)

    # Set up common test data
    @attachment = attachments(:attachment1) # fastq format
  end

  test 'should redirect with alert when attachment not found' do
    get attachment_path(id: 'non-existent-id')

    assert_redirected_to root_path
    assert_equal I18n.t('attachment.show.file_not_found'), flash[:alert]
  end

  test 'should handle unauthorized access' do
    sign_in users(:jane_doe)

    get attachment_path(@attachment)
    assert_response :unauthorized
  end

  test 'user can preview workflow execution attachment' do
    sign_in users(:john_doe)
    get attachment_path(attachments(:workflow_execution_completed_output_attachment))

    assert_response :success
  end

  test 'user can preview samples workflow execution attachment' do
    sign_in users(:john_doe)
    get attachment_path(attachments(:samples_workflow_execution_completed_output_attachment))

    assert_response :success
  end

  test 'user with role >= guest for project can preview sample attachment' do
    sign_in users(:ryan_doe)
    get attachment_path(@attachment)

    assert_response :success
  end

  test 'user with role >= analyst can preview project attachment' do
    attachment = attachments(:attachmentCSV)
    sign_in users(:michelle_doe)

    get attachment_path(attachment)

    assert_response :success
  end

  test 'user with role == guest cannot preview project attachment' do
    attachment = attachments(:attachmentCSV)
    sign_in users(:ryan_doe)
    get attachment_path(attachment)

    assert_response :unauthorized
  end

  test 'user with role >= analyst can preview group attachment' do
    attachment = attachments(:group16AttachmentCSV)
    sign_in users(:james_doe)

    get attachment_path(attachment)

    assert_response :success
  end

  test 'user with role == guest cannot preview group attachment' do
    attachment = attachments(:group16AttachmentCSV)
    sign_in users(:ryan_doe)

    get attachment_path(attachment)

    assert_response :unauthorized
  end

  test 'can preview a csv file' do
    attachment = attachments(:attachmentCSV)
    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'table'
    assert_select 'thead th', count: 10
    assert_select 'tbody tr', count: 15
  end

  test 'can preview a tsv file' do
    attachment = attachments(:attachmentTSV)
    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'table'
    assert_select 'thead th', count: 8
    assert_select 'tbody tr', count: 10
  end

  test 'can preview a text file' do
    attachment = attachments(:attachmentText)
    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'span', text: 'This is some valid text.'
  end

  test 'can preview a json file' do
    attachment = attachments(:attachmentJSON)
    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'pre', count: 1002
  end

  test 'can preview a spreadsheet file' do
    attachment = attachments(:attachmentSpreadsheet)
    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/, count: 0
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'table'
    assert_select 'thead th', count: 10
    assert_select 'tbody tr', count: 15
  end

  test 'can preview an image file' do
    attachment = attachments(:attachmentImage)
    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/, count: 0
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'img', count: 1,
                         attributes: {
                           alt: I18n.t('attachment.show.image.alt', filename: attachment.file.filename.to_s)
                         }
  end

  test 'can not preview an unsupported file type' do
    attachment = Attachment.create!(
      attachable: projects(:project1).namespace,
      file: fixture_file_upload('unsupported_file_type.bin', 'application/octet-stream')
    )
    get attachment_path(attachment)

    assert_redirected_to root_path
    assert_equal I18n.t('attachment.show.file_not_previewable'), flash[:alert]
  end
end

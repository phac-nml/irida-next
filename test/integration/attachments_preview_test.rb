# frozen_string_literal: true

require 'test_helper'

class AttachmentsPreviewTest < ActionDispatch::IntegrationTest
  test 'can preview image files' do
    sign_in users(:john_doe)
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

  test 'can preview text files' do
    sign_in users(:john_doe)
    attachment = attachments(:attachmentText)

    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'span', text: 'This is some valid text.'
  end

  test 'can preview fasta files' do
    sign_in users(:john_doe)
    attachment = attachments(:attachment3)

    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'span', text: '>AF411450.1 Borrelia burgdorferi B31 OspC (ospC) gene, partial cds'
  end

  test 'can preview fastq files' do
    sign_in users(:john_doe)
    attachment = attachments(:attachment1)

    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'span', text: '@M01648:39:000000000-A2K80:1:1101:16244:1505 1:N:0:1'
  end

  test 'can preview genbank files' do
    sign_in users(:john_doe)
    attachment = Attachment.create!(
      attachable: projects(:project1).namespace,
      file: fixture_file_upload('sequence.gbk', 'application/octet-stream'),
      metadata: { 'format' => 'genbank', 'compression' => 'none' }
    )

    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'span', text: 'LOCUS SCU49845 5028 bp DNA linear PLN 29-OCT-2018'
  end

  test 'can preview json files' do
    sign_in users(:john_doe)
    attachment = attachments(:attachmentJSON)

    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'pre', count: 1002
  end

  test 'can preview csv files' do
    sign_in users(:john_doe)
    attachment = attachments(:attachmentCSV)

    get attachment_path(attachment)

    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'button', text: /#{I18n.t('attachment.show.copy')}/
    assert_select 'button', text: I18n.t('common.actions.download')
    assert_select 'table'
    assert_select 'thead th', count: 10
    assert_select 'tbody tr', count: 15
  end

  test 'can preview tsv files' do
    sign_in users(:john_doe)
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

  test 'can preview spreadsheet files' do
    sign_in users(:john_doe)
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

  test 'cannot preview unsupported file types' do
    sign_in users(:john_doe)
    attachment = Attachment.create!(
      attachable: projects(:project1).namespace,
      file: fixture_file_upload('unsupported_file_type.bin', 'application/octet-stream')
    )

    get attachment_path(attachment)

    assert_redirected_to root_path
    assert_equal I18n.t('attachment.show.file_not_previewable'), flash[:alert]
  end

  test 'cannot preview non-existent attachment' do
    sign_in users(:john_doe)

    get attachment_path(id: 'non-existent-id')

    assert_redirected_to root_path
    assert_equal I18n.t('attachment.show.file_not_found'), flash[:alert]
  end

  test 'cannot preview attachment without authorization' do
    sign_in users(:ryan_doe)
    attachment = attachments(:attachmentCSV)

    get attachment_path(attachment)

    assert_response :unauthorized
  end

  test 'can preview attachment with role >= analyst for project' do
    sign_in users(:michelle_doe)
    attachment = attachments(:attachmentCSV)

    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
  end

  test 'can preview attachment with role >= analyst for group' do
    sign_in users(:james_doe)
    attachment = attachments(:group16AttachmentCSV)

    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
  end

  test 'cannot preview attachment with role == guest for project' do
    sign_in users(:ryan_doe)
    attachment = attachments(:attachmentCSV)

    get attachment_path(attachment)

    assert_response :unauthorized
  end

  test 'cannot preview attachment with role == guest for group' do
    sign_in users(:ryan_doe)
    attachment = attachments(:group16AttachmentCSV)

    get attachment_path(attachment)
    assert_response :unauthorized
  end

  test 'can preview attachment with role >= guest for sample' do
    sign_in users(:ryan_doe)
    attachment = attachments(:attachment1)

    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
  end

  test 'user can preview workflow execution attachment' do
    sign_in users(:john_doe)
    attachment = attachments(:workflow_execution_completed_output_attachment)
    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'a', I18n.t('shared.workflow_executions.index.title')
    assert_select 'a', attachment.attachable.name
  end

  test 'user can preview samples workflow execution attachment' do
    sign_in users(:john_doe)
    attachment = attachments(:samples_workflow_execution_completed_output_attachment)
    get attachment_path(attachment)

    assert_response :success
    assert_select 'h1', text: attachment.file.filename.to_s
    assert_select 'a', I18n.t('shared.workflow_executions.index.title')
    assert_select 'a', attachment.attachable.workflow_execution.name
  end
end

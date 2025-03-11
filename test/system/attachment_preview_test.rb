# frozen_string_literal: true

require 'application_system_test_case'

class AttachmentPreviewTest < ApplicationSystemTestCase
  def setup
    Flipper.enable(:attachments_preview)
    @user = users(:john_doe)
    login_as @user
  end

  test 'can preview a csv file' do
    attachment = attachments(:attachmentCSV)
    visit attachment_path(attachments(:attachmentCSV))
    assert_selector 'h1', text: attachment.file.filename.to_s
    assert_button I18n.t('attachment.show.copy')
    assert_link I18n.t('attachment.show.download')

    assert_selector 'table', count: 1
    assert_selector 'thead th', count: 10
    assert_selector 'tbody tr', count: 15
  end

  test 'can preview a tsv file' do
    attachment = attachments(:attachmentTSV)
    visit attachment_path(attachments(:attachmentTSV))
    assert_selector 'h1', text: attachment.file.filename.to_s
    assert_button I18n.t('attachment.show.copy')
    assert_link I18n.t('attachment.show.download')

    assert_selector 'table', count: 1
    assert_selector 'thead th', count: 8
    assert_selector 'tbody tr', count: 10
  end

  test 'can preview a text file' do
    attachment = attachments(:attachmentText)
    visit attachment_path(attachments(:attachmentText))
    assert_selector 'h1', text: attachment.file.filename.to_s
    assert_button I18n.t('attachment.show.copy')
    assert_link I18n.t('attachment.show.download')
    assert_text 'This is some valid text.'
  end

  test 'can preview a json file' do
    attachment = attachments(:attachmentJSON)
    visit attachment_path(attachments(:attachmentJSON))
    assert_selector 'h1', text: attachment.file.filename.to_s
    assert_button I18n.t('attachment.show.copy')
    assert_link I18n.t('attachment.show.download')

    assert_selector 'pre', count: 1002
  end

  test 'can preview a spreadsheet file' do
    attachment = attachments(:attachmentSpreadsheet)
    visit attachment_path(attachments(:attachmentSpreadsheet))
    assert_selector 'h1', text: attachment.file.filename.to_s
    assert_no_selector 'button', text: I18n.t('attachment.show.copy')
    assert_link I18n.t('attachment.show.download')

    assert_selector 'table', count: 1
    assert_selector 'thead th', count: 10
    assert_selector 'tbody tr', count: 15
  end

  test 'can preview an image file' do
    attachment = attachments(:attachmentImage)
    visit attachment_path(attachments(:attachmentImage))
    assert_selector 'h1', text: attachment.file.filename.to_s
    assert_no_selector 'button', text: I18n.t('attachment.show.copy')
    assert_link I18n.t('attachment.show.download')
    assert_selector "img[alt='#{I18n.t('attachment.show.image.alt', filename: attachment.file.filename.to_s)}']",
                    count: 1
  end
end

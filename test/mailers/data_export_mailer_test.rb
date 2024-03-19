# frozen_string_literal: true

require 'test_helper'

class DataExportMailerTest < ActionMailer::TestCase
  test 'export ready email with export name' do
    freeze_time
    data_export = data_exports(:data_export_four)
    email = DataExportMailer.export_ready(data_export)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [data_export.user.email], email.to
    assert_equal I18n.t('mailers.data_export_mailer.email_subject'), email.subject
    assert_match "#{I18n.t('mailers.data_export_mailer.export_ready.greeting')} #{data_export.user.first_name}",
                 email.body.to_s
    assert_no_match data_export.id, email.body.to_s
    assert_match 3.business_days.from_now.strftime('%A, %B %d, %Y'), email.body.to_s
  end

  test 'export ready email without export name' do
    freeze_time
    data_export = data_exports(:data_export_five)
    email = DataExportMailer.export_ready(data_export)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [data_export.user.email], email.to
    assert_equal I18n.t('mailers.data_export_mailer.email_subject'), email.subject
    assert_match "#{I18n.t('mailers.data_export_mailer.export_ready.greeting')} #{data_export.user.first_name}",
                 email.body.to_s
    assert_match data_export.id, email.body.to_s
    assert_match 3.business_days.from_now.strftime('%A, %B %d, %Y'), email.body.to_s
  end
end

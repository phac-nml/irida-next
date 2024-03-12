# frozen_string_literal: true

# Mailer used by data exports to notify users when export is ready for download
class DataExportMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def export_ready(data_export)
    @user = data_export.user
    @data_export = data_export
    mail(to: @user.email, subject: t(:'mailers.data_export_mailer.email_subject'))
  end
end

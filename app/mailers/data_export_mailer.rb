# frozen_string_literal: true

# Mailer used by data exports to notify users when export is ready for download
class DataExportMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def notification(data_export)
    @user = data_export.user
    @data_export = data_export
    mail(to: @user.email, subject: 'Welcome to My Awesome Site')
  end
end

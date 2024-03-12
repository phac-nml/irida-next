# frozen_string_literal: true

# Mailer used by data exports to notify users when export is ready for download
class DataExportMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def notification(data_export)
    puts 'hi in notification email dataexportmailer'
    @user = data_export.user
    @data_export = data_export
    puts 'about to mail'
    mail(to: 'chris.huynh333@gmail.com', subject: 'Welcome to My Awesome Site')
    puts 'finished mailer'
  end
end

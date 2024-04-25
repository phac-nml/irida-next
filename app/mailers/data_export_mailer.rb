# frozen_string_literal: true

# Mailer used by data exports to notify users when export is ready for download
class DataExportMailer < ApplicationMailer
  def export_ready(data_export)
    @user = data_export.user
    @data_export = data_export
    I18n.with_locale(@user.locale) do
      mail(to: @user.email,
           subject: t(:'mailers.data_export_mailer.email_subject', name: @data_export.name || @data_export.id))
    end
  end
end

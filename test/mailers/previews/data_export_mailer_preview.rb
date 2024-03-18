# frozen_string_literal: true

class DataExportMailerPreview < ActionMailer::Preview
  def export_ready
    data_export = DataExport.last
    DataExportMailer.export_ready(data_export)
  end
end

# frozen_string_literal: true

class DataExportMailerPreview < ActionMailer::Preview
  def export_ready_with_name
    data_export = DataExport.find_by(name: 'Seeded export 4')
    DataExportMailer.export_ready(data_export)
  end

  def export_ready_without_name
    data_export = DataExport.second
    DataExportMailer.export_ready(data_export)
  end
end

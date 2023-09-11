# frozen_string_literal: true

module NextflowHelper
  def nextflow_schema_from_file(filename)
    path = Rails.root.join('tmp', filename)
    JSON.parse(File.read(path))
  end
end

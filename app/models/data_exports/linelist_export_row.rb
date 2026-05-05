# frozen_string_literal: true

module DataExports
  # Value object for a sample row returned by the linelist export GraphQL field.
  # Keeps metadata key filtering server-side to match upload/create export rules.
  LinelistExportRow = Data.define(:sample, :metadata_keys) do
    delegate :name, :project, :puid, to: :sample

    def metadata
      keys = metadata_keys
      return sample.metadata if keys.blank?

      sample.metadata.slice(*keys)
    end
  end
end

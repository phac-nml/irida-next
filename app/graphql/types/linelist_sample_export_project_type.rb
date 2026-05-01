# frozen_string_literal: true

module Types
  # Minimal project shape for linelist export (avoids ProjectType authorization).
  class LinelistSampleExportProjectType < GraphQL::Schema::Object
    field_class Types::BaseField

    description 'Minimal project shape for linelist export.'

    field :puid, ID, null: false, description: 'Persistent Unique Identifier of the project.'

    def self.authorized?(_object, _context)
      true
    end
  end
end

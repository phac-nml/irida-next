# frozen_string_literal: true

module Types
  # Sample row for client-side linelist export; authorized in the resolver, not via SampleType.
  class LinelistSampleExportRowType < Types::BaseObject
    description 'Sample metadata row for linelist export (namespace-scoped, analyst-level access).'

    field :id, ID, null: false, description: 'Relay global ID of the sample.'
    field :metadata, GraphQL::Types::JSON, null: false, description: 'Metadata for the sample.'
    field :name, String, null: false, description: 'Name of the sample.'
    field :project, Types::LinelistSampleExportProjectType, null: false, description: 'Project the sample is on.'
    field :puid, ID, null: false, description: 'Persistent Unique Identifier of the sample.'

    def id
      IridaSchema.id_from_object(object.sample)
    end

    def self.authorized?(_object, _context)
      true
    end
  end
end

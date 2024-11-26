# frozen_string_literal: true

module Types
  # User Type
  class PipelineType < Types::BaseObject
    description 'A pipeline'

    field :automatable, GraphQL::Types::Boolean, null: true, description: ''
    field :description, String, null: true, description: ''
    field :engine, String, null: true, description: ''
    field :engine_version, String, null: true, description: ''
    field :executable, GraphQL::Types::Boolean, null: true, description: ''
    field :metadata, GraphQL::Types::JSON, description: ''
    field :name, String, null: true, description: ''
    field :type, String, null: true, description: ''
    field :type_version, String, null: true, description: ''
    field :url, String, null: false, description: 'URL of the pipeline GitHub repository'
    field :version, String, null: true, description: ''
    field :workflow_params, GraphQL::Types::JSON, null: false, description: ''

    def self.authorized?(object, context)
      super && true # Pipelines are not hidden from any users
    end
  end
end

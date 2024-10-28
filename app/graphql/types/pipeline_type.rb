# frozen_string_literal: true

module Types
  # User Type
  class PipelineType < Types::BaseType
    implements GraphQL::Types::Relay::Node
    description 'A pipeline'

    field :automatable, GraphQL::Types::Boolean, null: true, description: ''
    field :description, String, null: true, description: ''
    field :engine, String, null: true, description: ''
    field :engine_version, String, null: true, description: ''
    field :executable, String, null: true, description: ''
    field :metadata, GraphQL::Types::JSON, description: ''
    field :name, String, null: true, description: ''
    # field :overrides, GraphQL::Types::JSON, description: ''
    field :samplesheet_headers, GraphQL::Types::JSON, null: false, description: ''
    field :type, String, null: true, description: ''
    field :type_version, String, null: true, description: ''
    field :url, String, null: false, description: 'URL of the pipeline GitHub repository'
    field :version, String, null: true, description: ''
    field :workflow_params, GraphQL::Types::JSON, null: false, description: ''

    # def self.authorized?(object, context)
    #   super && allowed_to?(
    #     :read?,
    #     object,
    #     context: { user: context[:current_user], token: context[:token] }
    #   )
    # end
  end
end

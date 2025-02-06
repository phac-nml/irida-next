# frozen_string_literal: true

require 'graphql/searchkick/relation_connection'

# IridaSchema
class IridaSchema < GraphQL::Schema # rubocop:disable GraphQL/ObjectDescription
  query Types::QueryType
  mutation Types::MutationType

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  use GraphQL::Dataloader

  # Add in connection for Searchkick results
  connections.add(Searchkick::Relation, Graphql::Searchkick::RelationConnection)

  max_depth 15
  max_complexity 550
  default_page_size 25
  default_max_page_size 100

  # GraphQL-Ruby calls this when something goes wrong while running a query:
  def self.type_error(err, context) # rubocop:disable Lint/UselessMethodDefinition
    # if err.is_a?(GraphQL::InvalidNullError)
    #   # report to your bug tracker here
    #   return nil
    # end
    super
  end

  # Union and Interface Resolution
  def self.resolve_type(_type, object, _ctx) # rubocop:disable Metrics/MethodLength
    case object
    when Group
      Types::GroupType
    when Project
      Types::ProjectType
    when Sample
      Types::SampleType
    when Attachment
      Types::AttachmentType
    when User
      Types::UserType
    when WorkflowExecution
      Types::WorkflowExecutionType
    else
      raise(GraphQL::RequiredImplementationMissingError)
    end
  end

  # Stop validating when it encounters this many errors:
  validate_max_errors 100

  def self.execute(query_str = nil, **kwargs)
    Current.token = kwargs[:context][:token]
    super
  end

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, _type = nil, _ctx = nil)
    unless object.respond_to?(:to_global_id)
      raise GraphQL::CoercionError, "#{object} does not implement `to_global_id`."
    end

    object.to_global_id
  end

  # Find an object by looking it up from its global ID, passed as a string.
  def self.object_from_id(global_id, ctx = {})
    gid = parse_gid(global_id, ctx)

    GlobalID.find(gid)
  end

  # Parse a string to a GlobalID, raising if there are problems with it.
  def self.parse_gid(global_id, ctx = {})
    expected_types = Array(ctx[:expected_type])
    gid = GlobalID.parse(global_id)

    raise GraphQL::CoercionError, "#{global_id} is not a valid IRIDA Next ID." if !gid || gid.app != GlobalID.app

    if expected_types.any? && expected_types.none? { |type| gid.model_class.ancestors.include?(type) }
      raise GraphQL::CoercionError, "#{global_id} is not a valid ID for #{expected_types.join(', ')}"
    end

    gid
  end

  def self.unauthorized_object(error)
    # Add a top-level error to the response instead of returning nil:
    raise GraphQL::ExecutionError, "An object of type #{error.type.graphql_name} was hidden due to permissions"
  end

  def self.unauthorized_field(error)
    # Add a top-level error to the response instead of returning nil:
    raise GraphQL::ExecutionError,
          "The field #{error.field.graphql_name} on an object of type " \
          "#{error.type.graphql_name} was hidden due to permissions"
  end

  rescue_from(ActionPolicy::Unauthorized) do |exp|
    raise GraphQL::ExecutionError.new(
      # use result.message (backed by i18n) as an error message
      exp.result.message,
      # use GraphQL error extensions to provide more context
      extensions: {
        code: :unauthorized,
        fullMessages: exp.result.reasons.full_messages,
        details: exp.result.reasons.details
      }
    )
  end

  rescue_from(ActionPolicy::AuthorizationContextMissing) do
    raise GraphQL::ExecutionError, 'Unable to access object while accessing the API in guest mode'
  end

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
    raise GraphQL::CoercionError, exception
  end
end

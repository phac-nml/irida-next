# frozen_string_literal: true

# Graphql Controller
class GraphqlController < ApplicationController
  include SessionlessAuthentication
  include LastUsedIpConcern

  # Unauthenticated users have access to the API for public data
  skip_before_action :authenticate_user!

  # this was only needed for accessing current user in view components
  skip_around_action :set_current_user

  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  skip_forgery_protection with: :null_session, only: :execute

  # must come first: current_user is set up here
  before_action :authenticate_sessionless_user!, only: [:execute]

  # GraphQL mutations must be submitted via POST so Rails' CSRF protection can apply to them;
  # CSRF verification is always a no-op for GET requests, regardless of forgery protection config.
  before_action :reject_mutation_over_get!, only: [:execute]

  around_action :use_logidze_responsible, only: [:execute]

  def execute
    variables = prepare_variables(params[:variables])
    operation_name = params[:operationName]
    update_last_used_ips(context[:token], request.remote_ip)
    result = IridaSchema.execute(query, variables:, context:, operation_name:)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  def query
    params.fetch(:query, '')
  end

  def context
    @context ||= { current_user:, token: }
  end

  private

  def reject_mutation_over_get!
    return unless mutation_requested? && !request.post?

    response.headers['Allow'] = 'POST'
    render json: { errors: [{ message: 'GraphQL mutations must be submitted via HTTP POST.' }] },
           status: :method_not_allowed
  end

  # Parses the submitted query, without executing it, to check whether the operation that would be
  # selected for execution (following the same operationName resolution graphql-ruby itself uses) is
  # a mutation. Parse errors are swallowed here and left for IridaSchema.execute to report, so
  # error-reporting behaviour for malformed queries is unaffected.
  def mutation_requested?
    selected_operation = find_selected_operation
    selected_operation&.operation_type == 'mutation'
  rescue GraphQL::ParseError
    false
  end

  def find_selected_operation
    operations = {}
    GraphQL.parse(query).definitions.each do |definition|
      operations[definition.name] = definition if definition.is_a?(GraphQL::Language::Nodes::OperationDefinition)
    end
    return nil if operations.empty?

    operation_name = params[:operationName].presence
    return operations.values.first if operation_name.nil? && operations.length == 1

    operations[operation_name]
  end

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      variables_param.present? ? JSON.parse(variables_param) : {}
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(err)
    logger.error err.message
    logger.error err.backtrace.join("\n")

    render json: { errors: [{ message: err.message, backtrace: err.backtrace }], data: {} },
           status: :internal_server_error
  end
end

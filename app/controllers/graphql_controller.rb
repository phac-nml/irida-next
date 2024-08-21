# frozen_string_literal: true

# Graphql Controller
class GraphqlController < ActionController::Base # rubocop:disable Rails/ApplicationController
  include SessionlessAuthentication

  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  skip_forgery_protection with: :null_session

  # must come first: current_user is set up here
  before_action :authenticate_sessionless_user!

  def execute
    variables = prepare_variables(params[:variables])
    operation_name = params[:operationName]
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

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param) # rubocop:disable Metrics/MethodLength
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
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

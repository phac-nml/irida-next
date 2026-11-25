# frozen_string_literal: true

# Graphql Controller
class GraphqlController < ApplicationController
  include SessionlessAuthentication
  include LastUsedIpConcern

  # Unauthenticated users have access to the API for public data
  skip_before_action :authenticate_user!

  # must come first: current_user is set up here
  prepend_before_action :authenticate_sessionless_user!, only: [:execute]

  # this was only needed for accessing current user in view components
  skip_around_action :set_current_user

  # Skip CSRF for token-authenticated or anonymous requests; still enforce it for
  # browser-session-authenticated requests without a token.
  skip_before_action :verify_authenticity_token, if: :token_authenticated_or_anonymous?

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

  def token_authenticated_or_anonymous?
    token.present? || current_user.nil?
  end
end

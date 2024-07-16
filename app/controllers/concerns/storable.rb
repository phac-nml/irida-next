# frozen_string_literal: true

# Module Storable provides functionality to store and retrieve search parameters in the session.
# This module is designed to be included in controllers to manage search parameters efficiently.
module Storable
  extend ActiveSupport::Concern

  # Stores or retrieves search parameters in the session based on the request format.
  # If the request format is turbo_stream, it merges the provided search parameters
  # with any existing parameters under the given search_key in the session.
  # For non-turbo_stream requests, it either retrieves existing parameters or initializes
  # an empty hash if no parameters are stored under the search_key.
  #
  # @param search_key [Symbol, String] the key under which search parameters are stored in the session.
  # @param search_params [Hash] the search parameters to store or merge.
  # @return [Hash] the current search parameters stored in the session under the given search_key.
  def search_params(search_key, search_params)
    session[search_key] =
      request.format.turbo_stream? ? (session[search_key] || {}).merge(search_params) : session[search_key] || {}
    session[search_key]
  end
end

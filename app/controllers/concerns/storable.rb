# frozen_string_literal: true

# Module Storable provides functionality to store and retrieve search parameters in the session.
# This module is designed to be included in controllers to manage search parameters efficiently.
module Storable
  extend ActiveSupport::Concern

  # Stores a value in the session under the given session_key.
  # @param session_key [Symbol, String] the key under which the value is stored in the session.
  # @param value [Object] the value to store in the session.
  def store(session_key, value)
    session[session_key] = value
  end

  # Updates the stored value for a given search_key by merging it with the provided value.
  # If no value exists under the search_key, initializes it as an empty hash before merging.
  # @param search_key [Symbol, String] the key under which the value is stored in the session.
  # @param value [Hash] the value to merge with the existing value in the session.
  def update_store(search_key, value)
    session[search_key] = (session[search_key] || {}).merge(value)
    get_store(search_key)
  end

  # Retrieves the value stored in the session under the given session_key.
  # @param session_key [Symbol, String] the key for which the value is retrieved.
  # @return [Object] the value stored in the session under the session_key.
  def get_store(session_key)
    session[session_key]
  end
end

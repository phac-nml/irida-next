# frozen_string_literal: true

# Executes basic metadata logic for controllers
module Metadata
  extend ActiveSupport::Concern

  included do
    helper_method :fields_for_namespace
  end

  def fields_for_namespace(namespace: nil, show_fields: false)
    @fields = !show_fields || namespace.nil? ? [] : namespace.metadata_summary.keys
  end
end

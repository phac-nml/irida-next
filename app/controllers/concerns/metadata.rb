# frozen_string_literal: true

# Executes basic metadata template logic for controllers
module Metadata
  extend ActiveSupport::Concern

  included do
    helper_method :fields_for_namespace
  end

  def fields_for_namespace(namespace = nil, template_id = 0)
    @fields = template_id.zero? || namespace.nil? ? [] : namespace.metadata_summary.keys
  end
end

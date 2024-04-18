# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class NextflowComponent < Component
  include NextflowHelper

  attr_reader :schema, :url, :workflow, :metadata_fields, :samples, :namespace_id

  def initialize(url:, samples:, workflow:, fields:, namespace_id:, allowed_to_update_samples: true) # rubocop:disable Metrics/ParameterLists
    @samples = samples
    @namespace_id = namespace_id
    @url = url
    @workflow = workflow
    @metadata_fields = fields
    @allowed_to_update_samples = allowed_to_update_samples
  end
end

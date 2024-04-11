# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class NextflowComponent < Component
  include NextflowHelper

  attr_reader :schema, :url, :workflow, :metadata_fields

  def initialize(url:, samples:, workflow:, fields:, allowed_to_update_samples: true)
    @samples = samples
    @url = url
    @workflow = workflow
    @metadata_fields = fields
    @allowed_to_update_samples = allowed_to_update_samples
  end
end

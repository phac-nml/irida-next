# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class NextflowComponent < Component
  include NextflowHelper

  attr_reader :schema, :url, :workflow

  def initialize(url:, samples:, workflow:, allowed_to_update_samples: true)
    @samples = samples
    @url = url
    @workflow = workflow
    @allowed_to_update_samples = allowed_to_update_samples
  end
end

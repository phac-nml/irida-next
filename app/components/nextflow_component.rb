# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class NextflowComponent < Component
  include NextflowHelper

  attr_reader :schema, :url, :workflow, :metadata_fields, :samples, :namespace_id, :instance

  # rubocop:disable Metrics/ParameterLists
  def initialize(url:, samples:, workflow:, fields:, namespace_id:, allowed_to_update_samples: true, instance: nil)
    @samples = samples
    @namespace_id = namespace_id
    @url = url
    @workflow = workflow
    @metadata_fields = fields
    @allowed_to_update_samples = allowed_to_update_samples
    @instance = instance
  end

  # rubocop:enable Metrics/ParameterLists

  def text_for_description(description)
    if description.instance_of?(String)
      description
    else
      description[I18n.locale]
    end
  end
end

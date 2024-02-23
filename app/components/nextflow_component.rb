# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class NextflowComponent < Component
  include NextflowHelper

  attr_reader :schema, :url, :workflow

  def initialize(url:, samples:, workflow:)
    @samples = samples
    @schema = JSON.parse(workflow.schema_loc.read)
    @url = url
    @workflow = workflow
  end

  def show_section?(properties)
    properties.values.any? { |property| !property.key?('hidden') }
  end
end

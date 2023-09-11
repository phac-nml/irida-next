# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class NextflowComponent < Component
  include NextflowHelper

  attr_reader :schema, :url

  def initialize(schema_file:, url:)
    @schema = nextflow_schema_from_file(schema_file)
    @url = url
  end
end

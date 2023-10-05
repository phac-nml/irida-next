# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class NextflowComponent < Component
  include NextflowHelper

  attr_reader :schema, :url

  def initialize(schema:, url:)
    @schema = schema
    @url = url
  end
end

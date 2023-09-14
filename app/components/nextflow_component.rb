# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class NextflowComponent < Component
  attr_reader :schema, :url

  def initialize(schema:, url:)
    @schema = schema
    @url = url
  end
end

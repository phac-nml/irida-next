# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class NextflowComponent < Component
  attr_reader :schema, :url

  def initialize(schema_file:, url:)
    @schema = JSON.parse(File.read(schema_file))
    @url = url
  end
end

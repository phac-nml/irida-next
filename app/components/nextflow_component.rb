# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class NextflowComponent < Component
  attr_reader :schema, :url

  def initialize(schema_file:, url:)
    path = Rails.root.join('tmp', schema_file)
    @schema = JSON.parse(File.read(path))
    @url = url
  end
end

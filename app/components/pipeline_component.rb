# frozen_string_literal: true

class PipelineComponent < ViewComponent::Base
  def initialize(*)
    file = Rails.root.join('tmp', 'nextflow_schema.json')
    file = File.read(file)
    @schema = JSON.parse(file)
    @title = @schema['title']
    @description = @schema['description']
    @definitions = @schema['definitions']
  end
end

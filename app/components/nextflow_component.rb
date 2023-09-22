# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class NextflowComponent < Component
  attr_reader :schema, :url

  def initialize(schema:, url:)
    @schema = schema
    @url = url
  end

  def input_type(property)
    if property['format'].present?
      case property['format']
      when 'file-path'
        return file_input(property)
      end
    end
    { type: property['type'] }
  end

  def file_input(property)
    { type: 'file', pattern: property['pattern'] }
  end
end

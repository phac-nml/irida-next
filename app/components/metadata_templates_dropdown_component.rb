# frozen_string_literal: true

# Render a dropdown for metadata templates
class MetadataTemplatesDropdownComponent < Component
  attr_reader :options, :form, :selected

  def initialize(metadata_templates: nil, form: nil, selected: nil)
    puts metadata_templates.inspect
    @metadata_templates = metadata_templates
    @form = form
    @selected = selected
  end

  def formatted_options
    [
      [
        'Metadata Fields',
        [['All Metadata Fields', 'all'], ['No Metadata Fields', 'none']]

      ],
      ['Metadata Templates', @metadata_templates]
    ]
  end
end

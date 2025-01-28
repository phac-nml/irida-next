# frozen_string_literal: true

# Render a dropdown for metadata templates
class MetadataTemplatesDropdownComponent < Component
  attr_reader :options, :form, :selected

  def initialize(metadata_templates: nil, form: nil, selected: 'none')
    @metadata_templates = metadata_templates
    @form = form
    @selected = selected
  end

  def formatted_options
    options = [
      [
        t('components.metadata_templates_dropdown.fields'),
        [[t('components.metadata_templates_dropdown.all'), 'all'],
         [t('components.metadata_templates_dropdown.none'), 'none']]
      ]
    ]

    if @metadata_templates.present?
      options << [t('components.metadata_templates_dropdown.templates'),
                  @metadata_templates]
    end
    options
  end
end

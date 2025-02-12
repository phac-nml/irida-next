# frozen_string_literal: true

# Executes basic metadata logic for controllers
module Metadata
  extend ActiveSupport::Concern

  # Handles pagination with custom metadata field sorting
  def pagy_with_metadata_sort(result) # rubocop:disable Metrics/AbcSize
    model = controller_name.classify.constantize
    if !@q.sorts.empty? && model.ransackable_attributes.exclude?(@q.sorts.first.name)
      field = @q.sorts.first.name.gsub('metadata_', '')
      dir = @q.sorts.first.dir
      result = result.order(model.metadata_sort(field, dir))
    end

    pagy(result)
  end

  # Returns metadata fields based on namespace or template selection
  def fields_for_namespace_or_template(namespace: nil, template: nil)
    @fields = if template.blank? || template == 'none' || namespace.nil?
                []
              elsif template == 'all'
                namespace.metadata_fields
              else
                template = MetadataTemplate.find_by(id: template)
                template.present? ? template.fields : []
              end
  end

  # Builds list of fields available for advanced search
  def advanced_search_fields(namespace)
    sample_fields = %w[name puid created_at updated_at attachments_updated_at]
    metadata_fields = namespace.metadata_fields
    metadata_fields.map! { |field| "metadata.#{field}" }
    @advanced_search_fields = sample_fields.concat(metadata_fields)
  end

  # Sets default metadata template if none selected
  def current_metadata_template_id(params)
    params[:metadata_template] = params[:metadata_template].presence || 'none'
  end

  # Returns array of metadata templates for dropdown selection
  def metadata_templates_for_namespace(namespace: nil)
    @metadata_templates = namespace.metadata_templates.map { |template| [template.name, template.id] }
  end

  # Gets or builds current metadata template information
  def current_metadata_template
    current_value = @search_params['metadata_template'] || 'none'
    @metadata_template = build_metadata_template(current_value)
  end

  private

  # Determines which type of template to build based on value
  def build_metadata_template(value)
    if %w[none all].include?(value)
      build_special_template(value)
    else
      build_regular_template(value)
    end
  end

  # Builds hash for special template types (none/all)
  def build_special_template(value)
    {
      id: value,
      name: t("shared.samples.metadata_templates.fields.#{value}")
    }
  end

  # Builds hash for regular metadata templates or falls back to 'none'
  def build_regular_template(value)
    template = MetadataTemplate.find_by(id: value)
    template.present? ? template_hash(template) : build_special_template('none')
  end

  # Formats template data into consistent hash structure
  def template_hash(template)
    {
      id: template.id,
      name: template.name
    }
  end
end

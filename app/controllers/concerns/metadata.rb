# frozen_string_literal: true

# Executes basic metadata logic for controllers
module Metadata
  extend ActiveSupport::Concern

  def pagy_with_metadata_sort(result) # rubocop:disable Metrics/AbcSize
    model = controller_name.classify.constantize
    if !@q.sorts.empty? && model.ransackable_attributes.exclude?(@q.sorts.first.name)
      field = @q.sorts.first.name.gsub('metadata_', '')
      dir = @q.sorts.first.dir
      result = result.order(model.metadata_sort(field, dir))
    end

    pagy(result)
  end

  def fields_for_namespace_or_template(namespace: nil, template: nil)
    @fields = if template == 'none' || namespace.nil?
                []
              elsif template == 'all'
                namespace.metadata_fields
              else
                MetadataTemplate.find_by(id: template).fields
              end
  end

  def advanced_search_fields(namespace)
    sample_fields = %w[name puid created_at updated_at attachments_updated_at]
    metadata_fields = namespace.metadata_fields
    metadata_fields.map! { |field| "metadata.#{field}" }
    @advanced_search_fields = sample_fields.concat(metadata_fields)
  end

  def current_metadata_template(params)
    params[:metadata_template] = params[:metadata_template].presence || 'none'
  end

  def metadata_templates_for_namespace(namespace: nil)
    @metadata_templates = namespace.metadata_templates.map { |template| [template.name, template.id] }
  end
end

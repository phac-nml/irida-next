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

  def fields_for_namespace(namespace: nil, show_fields: false)
    @fields = !show_fields || namespace.nil? ? [] : namespace.metadata_fields
  end

  def advanced_search_fields(namespace)
    sample_fields = %w[name puid created_at updated_at attachments_updated_at]
    metadata_fields = namespace.metadata_fields
    metadata_fields.map! { |field| "metadata.#{field}" }
    @advanced_search_fields = sample_fields.concat(metadata_fields)
  end
end

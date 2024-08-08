# frozen_string_literal: true

# Executes basic metadata logic for controllers
module Metadata
  extend ActiveSupport::Concern

  def pagy_with_metadata_sort(result, limit: Pagy::DEFAULT[:limit])
    model = controller_name.classify.constantize
    if !@q.sorts.empty? && model.ransackable_attributes.exclude?(@q.sorts.first.name)
      field = @q.sorts.first.name.gsub('metadata_', '')
      dir = @q.sorts.first.dir
      result = result.order(model.metadata_sort(field, dir))
    end

    pagy(result, limit:)
  end

  def fields_for_namespace(namespace: nil, show_fields: false)
    @fields = !show_fields || namespace.nil? ? [] : namespace.metadata_fields
  end
end

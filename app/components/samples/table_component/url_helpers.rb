# frozen_string_literal: true

module Samples
  class TableComponent < Component
    # URL generation helpers for the samples table component
    module UrlHelpers
      # Generates the URL for selecting samples based on namespace type.
      #
      # @param options [Hash] URL options to pass through
      # @return [String] the select samples URL
      def select_samples_url(**)
        if @namespace.type == 'Group'
          select_group_samples_url(@namespace, **)
        else
          select_namespace_project_samples_url(@namespace.parent, @namespace.project, **)
        end
      end

      # Generates the URL for sorting a field with toggle between asc/desc.
      #
      # @param field [String, Symbol] the field to sort by
      # @return [String] the sort URL with updated sort parameter
      def sort_url(field)
        sort_string = if field.to_s == @sort_key && @sort_direction == 'asc'
                        "#{field} desc"
                      else
                        "#{field} asc"
                      end

        if @namespace.type == 'Group'
          group_samples_url(@namespace, q: { sort: sort_string }, limit: @pagy.limit)
        else
          namespace_project_samples_url(@namespace.parent, @namespace.project, q: { sort: sort_string },
                                                                               limit: @pagy.limit)
        end
      end

      # Generates the URL for creating a new metadata template.
      #
      # @return [String] the new metadata template URL
      def new_metadata_template_url
        if @namespace.type == 'Group'
          helpers.new_group_metadata_template_path(@namespace)
        else
          helpers.new_namespace_project_metadata_template_path(@namespace.parent, @namespace.project)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Samples
  module Table
    # URL generation helpers for samples table components.
    module UrlHelpers
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

      def metadata_template_url
        if @namespace.type == 'Group'
          helpers.group_metadata_templates_path(@namespace)
        else
          helpers.namespace_project_metadata_templates_path(@namespace.parent, @namespace.project)
        end
      end
    end
  end
end

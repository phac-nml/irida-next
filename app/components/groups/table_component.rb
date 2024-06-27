# frozen_string_literal: true

module Groups
  # Component for rendering a table of Samples
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    def initialize(
      namespace_group_links,
      namespace,
      access_levels
    )
      @namespace_group_links = namespace_group_links
      @namespace = namespace
      @access_levels = access_levels
    end

    # def system_arguments
    #   { tag: 'div' }.deep_merge(@system_arguments).tap do |args|
    #     args[:id] = 'samples-table'
    #     args[:classes] = class_names(args[:classes], 'relative', 'overflow-x-auto')
    #     if @abilities[:select_samples]
    #       args[:data] ||= {}
    #       args[:data][:controller] = 'selection'
    #       args[:data][:'selection-total-value'] = @pagy.count
    #       args[:data][:'selection-action-link-outlet'] = '.action-link'
    #     end
    #   end
    # end

    # def wrapper_arguments
    #   {
    #     tag: 'div',
    #     classes: class_names('table-container'),
    #     data: { turbo: :temporary }
    #   }
    # end

    # def row_arguments(sample)
    #   { tag: 'tr' }.tap do |args|
    #     args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
    #     args[:id] = sample.id
    #   end
    # end

    # def render_cell(**arguments, &)
    #   render(Viral::BaseComponent.new(**arguments), &)
    # end

    # def select_samples_url(**)
    #   if @namespace.type == 'Group'
    #     select_group_samples_url(@namespace, **)
    #   else
    #     select_namespace_project_samples_url(@namespace.parent, @namespace.project, **)
    #   end
    # end

    # private

    # def columns
    #   columns = %i[puid name]
    #   columns << :project if @namespace.type == 'Group'
    #   columns += %i[created_at updated_at attachments_updated_at]
    #   columns
    # end
  end
end

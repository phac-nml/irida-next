# frozen_string_literal: true

module Samples
  # Wrapper component for rendering samples in Pathogen::DataGridComponent.
  class DataGridTableComponent < Component # rubocop:disable Metrics/ClassLength
    # Maximum number of metadata fields to display regardless of sample count
    MAX_METADATA_FIELDS_SIZE = 200
    # Target maximum number of table cells (rows × columns) for optimal performance
    TARGET_MAX_CELLS = 2000

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      samples,
      namespace,
      pagy,
      has_samples: true,
      abilities: {},
      metadata_fields: [],
      search_params: {},
      empty: {},
      **system_arguments
    )
      @samples = samples
      @namespace = namespace
      @pagy = pagy
      @has_samples = has_samples
      @abilities = abilities

      @metadata_fields, @show_metadata_fields_size_warning =
        apply_metadata_field_limit(metadata_fields)

      @search_params = search_params
      @empty = empty
      @system_arguments = system_arguments

      # use rpartition to split on the first space encountered from the right side
      # this allows us to sort by metadata fields which contain spaces
      @sort_key, _space, @sort_direction = (search_params['sort'] || '').rpartition(' ')

      @columns = columns
    end
    # rubocop:enable Metrics/ParameterLists

    def before_render
      return unless @show_metadata_fields_size_warning

      can_edit = @abilities[:edit_sample_metadata]
      @metadata_fields_size_warning_message = build_metadata_fields_size_warning_message(can_edit_metadata: can_edit)
    end

    def data_grid_arguments
      base_args = @system_arguments.dup
      base_args[:class] = class_names(base_args[:class], 'samples-data-grid')
      base_args
    end

    def data_grid_label(column)
      return I18n.t('samples.table_component.namespaces.puid') if column.to_s == 'namespaces.puid'

      I18n.t("samples.table_component.#{column}")
    end

    def data_grid_width(column)
      return puid_width if column == :puid

      nil
    end

    def data_grid_sticky?(column)
      %i[puid name].include?(column)
    end

    def data_grid_sticky_left(column)
      return 0 if column == :puid
      return puid_width if column == :name

      nil
    end

    def puid_width
      helpers.puid_width(object_class: Sample, has_checkbox: @abilities[:select_samples])
    end

    def highlight_term
      @search_params[:name_or_puid_cont] || @search_params['name_or_puid_cont']
    end

    def empty_state?
      return false if @has_samples && @pagy&.count.to_i.positive?

      true
    end

    def metadata_value(sample, field)
      sample.metadata[field]
    end

    def render_column_value(column, sample)
      renderers = column_renderers(sample)
      renderer = renderers.fetch(column.to_s, :render_default_column)
      send(renderer, column, sample)
    end

    private

    def column_renderers(_sample)
      {
        'puid' => :render_puid_column,
        'name' => :render_name_column,
        'namespaces.puid' => :render_project_puid_column,
        'created_at' => :render_created_at_column,
        'updated_at' => :render_updated_at_column,
        'attachments_updated_at' => :render_attachments_updated_at_column
      }
    end

    def render_puid_column(_column, sample)
      helpers.tag.span(
        helpers.highlight(
          sample.puid,
          highlight_term,
          highlighter: '<mark class="pathogen-data-grid__highlight">\\1</mark>'
        ),
        class: 'pathogen-data-grid__value pathogen-data-grid__value--mono'
      )
    end

    def render_name_column(_column, sample)
      helpers.link_to(
        helpers.sample_path(sample),
        data: { turbo: false },
        class: 'pathogen-data-grid__link pathogen-data-grid__link--sample'
      ) do
        helpers.highlight(
          sample.name,
          highlight_term,
          highlighter: '<mark class="pathogen-data-grid__highlight pathogen-data-grid__highlight--strong">\\1</mark>'
        )
      end
    end

    def render_project_puid_column(_column, sample)
      helpers.link_to(
        sample.project.puid,
        helpers.namespace_project_samples_path(sample.project.namespace.parent, sample.project),
        data: { turbo: false },
        class: 'pathogen-data-grid__link pathogen-data-grid__link--project'
      )
    end

    def render_created_at_column(_column, sample)
      helpers.local_date(sample.created_at, :long)
    end

    def render_updated_at_column(_column, sample)
      return if sample.updated_at.blank?

      helpers.local_time_ago(sample.updated_at)
    end

    def render_attachments_updated_at_column(_column, sample)
      return if sample.attachments_updated_at.blank?

      helpers.local_time_ago(sample.attachments_updated_at)
    end

    def render_default_column(column, sample)
      sample.public_send(column.to_sym)
    end

    def columns
      columns = %i[puid name]
      columns << 'namespaces.puid' if @namespace.is_a?(Group)
      columns += %i[created_at updated_at attachments_updated_at]
      columns
    end

    def calculate_max_metadata_fields
      return MAX_METADATA_FIELDS_SIZE if @samples.empty?

      (TARGET_MAX_CELLS / @samples.size).floor.clamp(1, MAX_METADATA_FIELDS_SIZE)
    end

    def apply_metadata_field_limit(metadata_fields)
      max_fields = calculate_max_metadata_fields
      limited_fields = metadata_fields.take(max_fields)
      show_warning = metadata_fields.count > max_fields
      [limited_fields, show_warning]
    end

    def build_metadata_fields_size_warning_message(can_edit_metadata: false)
      params = warning_interpolation_params

      if can_edit_metadata
        warning_message_with_link(params)
      else
        I18n.t('components.samples.table_component.metadata_fields_size_warning', **params)
      end
    end

    def warning_interpolation_params
      {
        calculated_limit: calculate_max_metadata_fields,
        sample_count: @samples.size,
        target_max_cells: TARGET_MAX_CELLS
      }
    end

    def warning_message_with_link(params)
      link_markup = create_template_link

      I18n.t(
        'components.samples.table_component.metadata_fields_size_warning_with_link_html',
        **params, create_template_link: link_markup
      )
    end

    def create_template_link
      helpers.link_to(
        I18n.t('components.samples.table_component.create_template_link'),
        metadata_template_url,
        class: 'pathogen-data-grid__link pathogen-data-grid__link--template',
        data: { turbo_frame: '_top' }
      )
    end

    def metadata_template_url
      if @namespace.is_a?(Group)
        helpers.group_metadata_templates_path(@namespace)
      else
        helpers.namespace_project_metadata_templates_path(@namespace.parent, @namespace.project)
      end
    end
  end
end

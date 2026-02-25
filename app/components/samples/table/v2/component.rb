# frozen_string_literal: true

module Samples
  module Table
    module V2
      # Data-grid samples table implementation.
      class Component < ::Component # rubocop:disable Metrics/ClassLength
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
          @metadata_fields = metadata_fields
          @search_params = search_params
          @empty = empty
          @system_arguments = system_arguments

          # use rpartition to split on the first space encountered from the right side
          # this allows us to sort by metadata fields which contain spaces
          @sort_key, _space, @sort_direction = (search_params['sort'] || '').rpartition(' ')

          @columns = columns
        end
        # rubocop:enable Metrics/ParameterLists

        def data_grid_arguments
          base_args = @system_arguments.dup
          base_args[:id] = 'samples-table'
          base_args[:class] = class_names(
            base_args[:class],
            'samples-data-grid',
            'table-container',
            '@2xl:flex',
            '@2xl:flex-col',
            '@3xl:shrink',
            '@3xl:min-h-0'
          )
          base_args[:data] ||= {}
          base_args[:data][:'samples-table-version'] = 'v2'
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
          !@has_samples
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
              highlighter: [
                '<mark class="pathogen-data-grid__highlight pathogen-data-grid__highlight--strong">\\1</mark>'
              ].join
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
      end
    end
  end
end

# frozen_string_literal: true

module AdvancedSearch
  # Single source of truth for advanced-search filter operators.
  #
  # Every operator is declared once as an {AdvancedSearch::Operator}. Consumers
  # (filtering, validation, field configuration, UI components and GraphQL) read
  # their operator sets from the query methods below instead of maintaining their
  # own literal lists, which previously drifted out of sync.
  #
  # The catalog is pure data: it never evaluates feature flags. Callers that need
  # to hide metadata operators evaluate the flag themselves and pass the result to
  # {.available} (or filter on {Operator#requires_metadata_flag}).
  class OperatorCatalog # rubocop:disable Metrics/ClassLength
    class << self
      def all
        @all ||= build_operators.freeze
      end

      def find(key)
        by_key[key]
      end

      def by_key
        @by_key ||= all.index_by(&:key).freeze
      end

      def keys
        @keys ||= all.map(&:key).freeze
      end

      # Operators available in a given context. When metadata operators are
      # disabled, operators flagged with +requires_metadata_flag+ are excluded.
      def available(metadata_operators_enabled:)
        return all if metadata_operators_enabled

        all.reject(&:requires_metadata_flag)
      end

      # --- Validation sets (AdvancedSearch::GroupValidator) ---

      def exists_operators
        @exists_operators ||= keys_where(&:exists).freeze
      end

      def between_operators
        @between_operators ||= keys_where(&:between).freeze
      end

      def metadata_date_operators
        @metadata_date_operators ||=
          keys_where { |op| op.metadata_data_type == :date && !op.exists }.freeze
      end

      def metadata_numeric_operators
        @metadata_numeric_operators ||=
          keys_where { |op| op.metadata_data_type == :numeric && !op.exists }.freeze
      end

      def non_metadata_operators
        @non_metadata_operators ||= keys_where(&:non_metadata).freeze
      end

      def non_metadata_numeric_operators
        @non_metadata_numeric_operators ||=
          keys_where { |op| op.non_metadata && op.numeric_value }.freeze
      end

      def date_operator_disallowed
        @date_operator_disallowed ||= keys_where(&:standard_date_disallowed).freeze
      end

      def combinable_operators
        @combinable_operators ||= all.each_with_object({}) do |op, groups|
          next if op.combinable_group.nil?

          (groups[op.combinable_group] ||= []) << op.key
        end.transform_values(&:freeze).freeze
      end

      # --- Field configuration sets (AdvancedSearch::Fields) ---

      def enum_operator_values
        @enum_operator_values ||= {
          'metadata' => keys_where(&:enum_metadata).freeze,
          'standard' => keys_where(&:enum_standard).freeze
        }.freeze
      end

      def numeric_operator_values
        @numeric_operator_values ||= keys_where(&:numeric_value).freeze
      end

      # --- UI option sets (advanced-search components) ---

      def ui_options(metadata_operators_enabled:)
        operators = available(metadata_operators_enabled:)
        options = {
          'standard' => options_for(operators.select { |op| op.ui_group == :standard }, :standard)
        }
        options['metadata'] = metadata_options(operators) if metadata_operators_enabled
        options
      end

      def enum_operator_options(metadata_operators_enabled:)
        options = ui_options(metadata_operators_enabled:)
        {
          'standard' => select_options(options.fetch('standard'), enum_operator_values.fetch('standard')),
          'metadata' => select_options(
            flatten_metadata_options(options.fetch('metadata', {})),
            enum_operator_values.fetch('metadata')
          )
        }.compact_blank
      end

      def numeric_operator_options
        select_options(ui_options(metadata_operators_enabled: false).fetch('standard'), numeric_operator_values)
      end

      def date_operator_options
        select_options(ui_options(metadata_operators_enabled: false).fetch('standard'), date_operator_values)
      end

      def metadata_operator_options
        ui_options(metadata_operators_enabled: true).fetch('metadata')
      end

      # Standard operators valid for non-metadata date fields (e.g. created_at).
      def date_operator_values
        @date_operator_values ||=
          keys_where { |op| op.ui_group == :standard && !op.standard_date_disallowed }.freeze
      end

      # --- GraphQL enum maps (Types::SampleAdvancedSearchConditionOperatorInputType) ---

      def graphql_standard_operators
        @graphql_standard_operators ||= graphql_map(:standard)
      end

      def graphql_metadata_operators
        @graphql_metadata_operators ||= graphql_map(:metadata)
      end

      private

      def keys_where(&)
        all.select(&).map(&:key)
      end

      def graphql_map(group)
        all.each_with_object({}) do |op, map|
          next unless op.graphql? && op.graphql_group == group

          map[op.graphql_name] = op.key
        end.freeze
      end

      def build_operators
        build_standard_operators + build_metadata_text_operators +
          build_metadata_numeric_operators + build_metadata_date_operators
      end

      # Standard operators for non-metadata fields.
      def build_standard_operators # rubocop:disable Metrics/MethodLength
        [
          op('=', label_key: :equals, arel_handler: :condition_equals, arel_args: %i[value field_name],
                  graphql_name: 'EQUALS', graphql_group: :standard,
                  non_metadata: true, numeric_value: true, enum_standard: true),
          op('!=', label_key: :not_equals, arel_handler: :condition_not_equals, arel_args: %i[value field_name],
                   graphql_name: 'NOT_EQUALS', graphql_group: :standard,
                   non_metadata: true, numeric_value: true, enum_standard: true),
          op('<=', label_key: :less_than, arel_handler: :condition_less_than_or_equal,
                   arel_args: %i[value metadata_key field_name],
                   graphql_name: 'LESS_THAN_EQUALS', graphql_group: :standard,
                   combinable_group: :gleqt, non_metadata: true, numeric_value: true),
          op('>=', label_key: :greater_than, arel_handler: :condition_greater_than_or_equal,
                   arel_args: %i[value metadata_key field_name],
                   graphql_name: 'GREATER_THAN_EQUALS', graphql_group: :standard,
                   combinable_group: :gleqt, non_metadata: true, numeric_value: true),
          op('contains', arel_handler: :condition_contains, arel_args: %i[value model_class field_name],
                         graphql_name: 'CONTAINS', graphql_group: :standard,
                         non_metadata: true, standard_date_disallowed: true),
          op('not_contains', label_key: :does_not_contain, arel_handler: :condition_not_contains,
                             arel_args: %i[value model_class field_name],
                             graphql_name: 'NOT_CONTAINS', graphql_group: :standard,
                             non_metadata: true, standard_date_disallowed: true),
          op('exists', arel_handler: :condition_exists, arel_args: [],
                       graphql_name: 'EXISTS', graphql_group: :standard, exists: true),
          op('not_exists', arel_handler: :condition_not_exists, arel_args: [],
                           graphql_name: 'NOT_EXISTS', graphql_group: :standard, exists: true),
          op('in', arel_handler: :condition_in, arel_args: %i[value field_name],
                   graphql_name: 'IN', graphql_group: :standard,
                   non_metadata: true, numeric_value: true, enum_standard: true,
                   standard_date_disallowed: true),
          op('not_in', arel_handler: :condition_not_in, arel_args: %i[value field_name],
                       graphql_name: 'NOT_IN', graphql_group: :standard,
                       non_metadata: true, numeric_value: true, enum_standard: true,
                       standard_date_disallowed: true),
          op('starts_with', arel_handler: :condition_starts_with, arel_args: %i[value model_class field_name],
                            combinable_group: :start_ends_with, non_metadata: true, standard_date_disallowed: true),
          op('ends_with', arel_handler: :condition_ends_with, arel_args: %i[value model_class field_name],
                          combinable_group: :start_ends_with, non_metadata: true, standard_date_disallowed: true),
          op('between', arel_handler: :condition_between, arel_args: %i[value field_name],
                        between: true, non_metadata: true, numeric_value: true)
        ]
      end

      # Metadata text operators (available only when metadata operators are enabled).
      def build_metadata_text_operators # rubocop:disable Metrics/MethodLength
        [
          op('text_equals', arel_handler: :condition_equals, arel_args: %i[value field_name],
                            ui_group: :metadata_text, graphql_name: 'TEXT_EQUALS', graphql_group: :metadata,
                            metadata_data_type: :text, requires_metadata_flag: true, enum_metadata: true),
          op('text_not_equals', arel_handler: :condition_not_equals, arel_args: %i[value field_name],
                                ui_group: :metadata_text, graphql_name: 'TEXT_NOT_EQUALS', graphql_group: :metadata,
                                metadata_data_type: :text, requires_metadata_flag: true, enum_metadata: true),
          op('text_contains', arel_handler: :condition_contains, arel_args: %i[value model_class field_name],
                              ui_group: :metadata_text, graphql_name: 'TEXT_CONTAINS', graphql_group: :metadata,
                              metadata_data_type: :text, requires_metadata_flag: true),
          op('text_not_contains', arel_handler: :condition_not_contains, arel_args: %i[value model_class field_name],
                                  ui_group: :metadata_text, graphql_name: 'TEXT_NOT_CONTAINS', graphql_group: :metadata,
                                  metadata_data_type: :text, requires_metadata_flag: true),
          op('text_in', arel_handler: :condition_in_metadata, arel_args: %i[value],
                        ui_group: :metadata_text, graphql_name: 'TEXT_IN', graphql_group: :metadata,
                        metadata_data_type: :text, requires_metadata_flag: true, enum_metadata: true),
          op('text_not_in', arel_handler: :condition_not_in_metadata, arel_args: %i[value],
                            ui_group: :metadata_text, graphql_name: 'TEXT_NOT_IN', graphql_group: :metadata,
                            metadata_data_type: :text, requires_metadata_flag: true, enum_metadata: true),
          op('text_starts_with', arel_handler: :condition_starts_with, arel_args: %i[value model_class field_name],
                                 ui_group: :metadata_text, metadata_data_type: :text,
                                 combinable_group: :text_starts_ends_with, requires_metadata_flag: true),
          op('text_ends_with', arel_handler: :condition_ends_with, arel_args: %i[value model_class field_name],
                               ui_group: :metadata_text, metadata_data_type: :text,
                               combinable_group: :text_starts_ends_with, requires_metadata_flag: true),
          op('text_between', arel_handler: :condition_text_between, arel_args: %i[value],
                             ui_group: :metadata_text, metadata_data_type: :text,
                             between: true, requires_metadata_flag: true)
        ]
      end

      # Metadata numeric operators (available only when metadata operators are enabled).
      def build_metadata_numeric_operators # rubocop:disable Metrics/MethodLength
        [
          op('numeric_equals', arel_handler: :metadata_condition_numeric_comparison, arel_args: %i[value eq],
                               ui_group: :metadata_numeric, graphql_name: 'NUMERIC_EQUALS', graphql_group: :metadata,
                               metadata_data_type: :numeric, requires_metadata_flag: true),
          op('numeric_not_equals', arel_handler: :metadata_condition_numeric_comparison, arel_args: %i[value not_eq],
                                   ui_group: :metadata_numeric, graphql_name: 'NUMERIC_NOT_EQUALS',
                                   graphql_group: :metadata, metadata_data_type: :numeric,
                                   requires_metadata_flag: true),
          op('numeric_less_than_equals', arel_handler: :metadata_condition_numeric_comparison,
                                         arel_args: %i[value lteq], ui_group: :metadata_numeric,
                                         graphql_name: 'NUMERIC_LESS_THAN_EQUALS', graphql_group: :metadata,
                                         metadata_data_type: :numeric, combinable_group: :metadata_numeric_gleqt,
                                         requires_metadata_flag: true),
          op('numeric_greater_than_equals', arel_handler: :metadata_condition_numeric_comparison,
                                            arel_args: %i[value gteq], ui_group: :metadata_numeric,
                                            graphql_name: 'NUMERIC_GREATER_THAN_EQUALS', graphql_group: :metadata,
                                            metadata_data_type: :numeric, combinable_group: :metadata_numeric_gleqt,
                                            requires_metadata_flag: true),
          op('numeric_exists', arel_handler: :condition_metadata_exists, arel_args: [:numeric],
                               ui_group: :metadata_numeric, graphql_name: 'NUMERIC_EXISTS', graphql_group: :metadata,
                               metadata_data_type: :numeric, exists: true, requires_metadata_flag: true),
          op('numeric_not_exists', arel_handler: :condition_metadata_not_exists, arel_args: [:numeric],
                                   ui_group: :metadata_numeric, graphql_name: 'NUMERIC_NOT_EXISTS',
                                   graphql_group: :metadata, metadata_data_type: :numeric, exists: true,
                                   requires_metadata_flag: true),
          op('numeric_between', arel_handler: :condition_numeric_between, arel_args: %i[value],
                                ui_group: :metadata_numeric, metadata_data_type: :numeric,
                                between: true, requires_metadata_flag: true)
        ]
      end

      # Metadata date operators (available only when metadata operators are enabled).
      def build_metadata_date_operators # rubocop:disable Metrics/MethodLength
        [
          op('date_equals', arel_handler: :condition_equals, arel_args: %i[value field_name],
                            ui_group: :metadata_date, graphql_name: 'DATE_EQUALS', graphql_group: :metadata,
                            metadata_data_type: :date, requires_metadata_flag: true),
          op('date_not_equals', arel_handler: :condition_not_equals, arel_args: %i[value field_name],
                                ui_group: :metadata_date, graphql_name: 'DATE_NOT_EQUALS', graphql_group: :metadata,
                                metadata_data_type: :date, requires_metadata_flag: true),
          op('date_less_than_equals', arel_handler: :metadata_condition_date_comparison, arel_args: %i[value lteq],
                                      ui_group: :metadata_date, graphql_name: 'DATE_LESS_THAN_EQUALS',
                                      graphql_group: :metadata, metadata_data_type: :date,
                                      combinable_group: :metadata_date_gleqt, requires_metadata_flag: true),
          op('date_greater_than_equals', arel_handler: :metadata_condition_date_comparison, arel_args: %i[value gteq],
                                         ui_group: :metadata_date, graphql_name: 'DATE_GREATER_THAN_EQUALS',
                                         graphql_group: :metadata, metadata_data_type: :date,
                                         combinable_group: :metadata_date_gleqt, requires_metadata_flag: true),
          op('date_exists', arel_handler: :condition_metadata_exists, arel_args: [:date],
                            ui_group: :metadata_date, graphql_name: 'DATE_EXISTS', graphql_group: :metadata,
                            metadata_data_type: :date, exists: true, requires_metadata_flag: true),
          op('date_not_exists', arel_handler: :condition_metadata_not_exists, arel_args: [:date],
                                ui_group: :metadata_date, graphql_name: 'DATE_NOT_EXISTS', graphql_group: :metadata,
                                metadata_data_type: :date, exists: true, requires_metadata_flag: true),
          op('date_between', arel_handler: :metadata_condition_date_between, arel_args: %i[value],
                             ui_group: :metadata_date, metadata_data_type: :date,
                             between: true, requires_metadata_flag: true)
        ]
      end

      # Builds an Operator with sensible defaults so each declaration only states
      # what differs from the common case (a standard, non-metadata operator).
      def op(key, arel_handler:, arel_args:, label_key: key, ui_group: :standard, graphql_name: nil, graphql_group: nil, # rubocop:disable Metrics/ParameterLists
             metadata_data_type: nil, combinable_group: nil, requires_metadata_flag: false, exists: false,
             between: false, non_metadata: false, numeric_value: false, enum_standard: false, enum_metadata: false,
             standard_date_disallowed: false)
        Operator.new(
          key:, label_key:, arel_handler:, arel_args: arel_args.freeze, ui_group:, graphql_name:, graphql_group:,
          metadata_data_type:, combinable_group:, requires_metadata_flag:, exists:, between:,
          non_metadata:, numeric_value:, enum_standard:, enum_metadata:, standard_date_disallowed:
        )
      end

      def options_for(operators, group)
        operators.to_h do |operator|
          [I18n.t("components.advanced_search_component.operations.#{group}.#{operator.label_key}"), operator.key]
        end
      end

      def metadata_options(operators) # rubocop:disable Metrics/AbcSize
        # rubocop:disable Layout/LineLength
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.text.text_equals')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.text.text_not_equals')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.text.text_contains')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.text.text_not_contains')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.text.text_in')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.text.text_not_in')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.text.text_starts_with')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.text.text_ends_with')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.text.text_between')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.numeric.numeric_equals')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.numeric.numeric_not_equals')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.numeric.numeric_less_than_equals')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.numeric.numeric_greater_than_equals')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.numeric.numeric_exists')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.numeric.numeric_not_exists')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.numeric.numeric_between')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.date.date_equals')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.date.date_not_equals')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.date.date_less_than_equals')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.date.date_greater_than_equals')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.date.date_exists')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.date.date_not_exists')
        # i18n-tasks-use t('components.advanced_search_component.operations.metadata.operations.date.date_between')
        # rubocop:enable Layout/LineLength
        {
          I18n.t('components.advanced_search_component.operations.metadata.labels.existence') =>
            options_for(operators.select { |op| op.exists && op.ui_group == :standard }, :standard),
          I18n.t('components.advanced_search_component.operations.metadata.labels.text') =>
            options_for(operators.select { |op| op.ui_group == :metadata_text }, 'metadata.operations.text'),
          I18n.t('components.advanced_search_component.operations.metadata.labels.numeric') =>
            options_for(operators.select { |op| op.ui_group == :metadata_numeric }, 'metadata.operations.numeric'),
          I18n.t('components.advanced_search_component.operations.metadata.labels.date') =>
            options_for(operators.select { |op| op.ui_group == :metadata_date }, 'metadata.operations.date')
        }.reject { |_, options| options.empty? }
      end

      def select_options(options, keys)
        options.select { |_, value| keys.include?(value) }
      end

      def flatten_metadata_options(options)
        options.values.reduce({}, :merge)
      end
    end
  end
end

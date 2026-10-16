# frozen_string_literal: true

module Samples
  # Adapts the existing Samples query to forward-only Pagy keyset pagination.
  # The caller must authorize the project before building the query.
  class CursorPage
    include Pagy::Method

    TOKEN_PURPOSE = 'samples_cursor_page'
    NULL_COLUMN = 'pvc_cursor_null'
    VALUE_COLUMN = 'pvc_cursor_value'
    TIMESTAMP_COLUMNS = %w[created_at updated_at attachments_updated_at].freeze
    SORT_COLUMNS = (%w[name puid] + TIMESTAMP_COLUMNS).freeze

    class InvalidCursor < ArgumentError; end
    class InvalidQuery < ArgumentError; end

    Result = Data.define(:records, :next_cursor, :row_offset, :limit)

    def initialize(query:, project:, query_params:, limit: nil, cursor: nil)
      @query = query
      @project = project
      @query_params = query_params.to_h
      requested_limit = Integer(limit, exception: false)
      default_limit = Pagy::OPTIONS.fetch(:limit)
      @limit = [requested_limit&.positive? ? requested_limit : default_limit, Pagy::OPTIONS.fetch(:max_limit)].min
      @cursor = cursor
    end

    def call
      validate_query!
      continuation = decode_cursor
      pagination, records = pagy(
        :keyset,
        cursor_relation.preload(project: { namespace: :parent }),
        page: continuation['page'],
        limit: @limit,
        request: { params: {} },
        pre_serialize: method(:serialize_sort_value)
      )
      row_offset = continuation.fetch('row_offset')

      Result.new(records:, next_cursor: encode_cursor(pagination.next, row_offset + records.length),
                 row_offset:, limit: @limit)
    end

    private

    def validate_query!
      return if @query.valid? && (SORT_COLUMNS.include?(@query.column) || @query.column.start_with?('metadata.'))

      raise InvalidQuery, 'Invalid project samples query'
    end

    def cursor_relation
      table = Sample.arel_table
      order = [NULL_COLUMN, VALUE_COLUMN, 'id'].map { |column| table[column].public_send(@query.direction) }

      # The alias must match the model table name used by Pagy's predicates.
      # Explicit Arel attributes let Pagy discover these projected column names.
      Sample.from(projected_relation, :samples).select(table[Arel.star]).reorder(*order)
    end

    def projected_relation
      @query.results.where(project_id: @project.id).reorder(nil)
            .select(Sample.arel_table[Arel.star], *sort_projection)
    end

    def sort_projection
      expression = sort_expression
      null_rank = Arel::Nodes::Case.new.when(expression.eq(nil)).then(1).else(0)
      value = Arel::Nodes::NamedFunction.new('COALESCE', [expression, sort_fallback])
      [null_rank.as(NULL_COLUMN), value.as(VALUE_COLUMN)]
    end

    def sort_expression
      return Sample.arel_table[@query.column] unless @query.column.start_with?('metadata.')

      Sample.metadata_sort(@query.column.delete_prefix('metadata.'), @query.direction).expr
    end

    def sort_fallback
      return Arel.sql("TIMESTAMP '1970-01-01 00:00:00'") if TIMESTAMP_COLUMNS.include?(@query.column)

      Arel::Nodes.build_quoted('')
    end

    def serialize_sort_value(attributes)
      return unless TIMESTAMP_COLUMNS.include?(@query.column)

      # The projected timestamp uses the database timezone and timestamp(6).
      # Avoid JSON's default millisecond precision in the continuation predicate.
      attributes[VALUE_COLUMN] = attributes.fetch(VALUE_COLUMN).strftime('%F %T.%6N')
    end

    def decode_cursor
      return { 'page' => nil, 'row_offset' => 0 } if @cursor.nil?

      payload = verifier.verified(@cursor, purpose: TOKEN_PURPOSE)
      return payload if valid_cursor_payload?(payload)

      raise InvalidCursor, 'Invalid or mismatched samples cursor'
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError, TypeError
      raise InvalidCursor, 'Invalid or mismatched samples cursor'
    end

    def valid_cursor_payload?(payload)
      payload.is_a?(Hash) && payload['version'] == 1 && payload['scope'] == query_fingerprint &&
        payload['page'].is_a?(String) && payload['page'].present? &&
        payload['row_offset'].is_a?(Integer) && payload['row_offset'].positive?
    end

    def encode_cursor(page, row_offset)
      return unless page

      verifier.generate({ 'version' => 1, 'scope' => query_fingerprint, 'page' => page, 'row_offset' => row_offset },
                        purpose: TOKEN_PURPOSE)
    end

    def query_fingerprint
      @query_fingerprint ||= Digest::SHA256.hexdigest(
        canonicalize({ project_id: @project.id, query: @query_params, column: @query.column,
                       direction: @query.direction, limit: @limit }).to_json
      )
    end

    def canonicalize(value)
      case value
      when Hash
        value.stringify_keys.sort.to_h.transform_values { |entry| canonicalize(entry) }
      when Array
        value.map { |entry| canonicalize(entry) }
      else
        value
      end
    end

    def verifier = Rails.application.message_verifier(TOKEN_PURPOSE)
  end
end

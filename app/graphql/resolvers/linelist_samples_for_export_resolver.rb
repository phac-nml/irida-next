# frozen_string_literal: true

module Resolvers
  # Resolves sample rows for client-side linelist export using the same rules as server-side export.
  class LinelistSamplesForExportResolver < BaseResolver
    type [Types::LinelistSampleExportRowType], null: false

    argument :namespace_id, GraphQL::Types::ID,
             required: true,
             description: 'Namespace ID (database id) the user is exporting from.'

    argument :sample_ids, [GraphQL::Types::ID],
             required: true,
             description: 'Database ids of samples to include (must all be exportable at analyst level).'

    argument :metadata_keys, [GraphQL::Types::String],
             required: false,
             default_value: nil,
             description: 'Optional metadata keys to include in each row.'

    def ready?(**)
      authorize!(to: :query?, with: GraphqlPolicy, context: { token: context[:token] })
      true
    end

    def resolve(namespace_id:, sample_ids:, metadata_keys: nil)
      namespace = Namespace.find(namespace_id)
      authorize_export!(namespace)

      ordered_ids = sample_ids.map(&:to_s).map(&:strip).compact_blank
      unique_ids = ordered_ids.uniq
      if unique_ids.size != ordered_ids.size
        raise GraphQL::ExecutionError, I18n.t('services.data_exports.create.invalid_export_samples')
      end

      indexed = exportable_samples_by_id(namespace, unique_ids)
      keys = metadata_keys.presence

      ordered_ids.map do |sid|
        sample = indexed[sid]
        DataExports::LinelistExportRow.new(sample:, metadata_keys: keys)
      end
    end

    private

    def authorize_export!(namespace)
      authorize!(namespace, to: :export_data?)
    end

    def exportable_samples_by_id(namespace, unique_ids)
      policy = SamplePolicy.new(namespace, user: context[:current_user])
      rows_scope = policy.apply_scope(
        Sample, type: :relation, name: :namespace_samples,
                scope_options: { namespace:, minimum_access_level: Member::AccessLevel::ANALYST }
      ).where(id: unique_ids).includes(:project)

      if rows_scope.count != unique_ids.size
        raise GraphQL::ExecutionError, I18n.t('services.data_exports.create.invalid_export_samples')
      end

      rows_scope.index_by { |sample| sample.id.to_s }
    end
  end
end

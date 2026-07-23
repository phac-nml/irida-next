# frozen_string_literal: true

# Namespace base class
class Namespace < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include FileSelector
  include HasPuid
  include Routable
  include TrackActivity
  include Namespaces::Traversal::RouteBased

  has_logidze
  acts_as_paranoid

  MAX_ANCESTORS = 10

  belongs_to :owner, class_name: 'User', optional: true

  belongs_to :parent, class_name: 'Namespace', optional: true

  has_many :children,
           lambda {
             where(type: Group.sti_name)
           },
           class_name: 'Namespace', foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy

  has_many :attachments, as: :attachable, dependent: :destroy

  validates :owner, presence: true, if: ->(n) { n.owner_required? }
  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :name, uniqueness: { case_sensitive: false, scope: %i[type] }, if: -> { parent_id.blank? }
  validates :name, uniqueness: { case_sensitive: false, scope: %i[type parent_id] }, if: -> { parent_id.present? }

  validates :description, length: { maximum: 255 }

  validates :path, presence: true, length: { minimum: 3, maximum: 255 }

  validates :path, namespace_path: true

  validate :validate_type, if: -> { new_record? || type_changed? }
  validate :validate_parent_type, if: -> { new_record? || parent_id_changed? }
  validate :validate_nesting_level, if: -> { new_record? || parent_id_changed? }

  scope :include_route, -> { includes(:route) }

  after_restore :restore_routes

  class << self
    def sti_class_for(type_name)
      case type_name
      when Group.sti_name
        Group
      when Namespaces::ProjectNamespace.sti_name
        Namespaces::ProjectNamespace
      when Namespaces::UserNamespace.sti_name
        Namespaces::UserNamespace
      else
        Namespace
      end
    end

    def by_path(path)
      find_by(arel_table[:path].lower.eq(path.downcase))
    end

    def ransackable_attributes(_auth_object = nil)
      %w[created_at deleted_at name puid updated_at]
    end

    def ransackable_associations(_auth_object = nil)
      %w[]
    end

    def subtract_from_metadata_summary_count(namespaces, metadata_summary, by_one)
      return if metadata_summary.empty?

      update_metadata_summary_counts(namespaces, metadata_summary, by_one: by_one, addition: false)
    end

    def add_to_metadata_summary_count(namespaces, metadata_summary, by_one)
      return if metadata_summary.empty?

      update_metadata_summary_counts(namespaces, metadata_summary, by_one: by_one, addition: true)
    end

    # Helper to build an Arel CONCAT(path, '/') node for route path equality
    # checks. Defaults to using the routes table `path` column but accepts a
    # custom Arel node (for aliased tables) when needed.
    def concat_path_with_slash(path_node = Route.arel_table[:path])
      Arel::Nodes::NamedFunction.new('CONCAT', [path_node, Arel::Nodes::Quoted.new('/')])
    end

    # Helper to build an Arel CONCAT(path, '/%') node for prefix/wildcard
    # matching. Accepts an optional path_node for aliased tables.
    def concat_path_with_wildcard(path_node = Route.arel_table[:path])
      Arel::Nodes::NamedFunction.new('CONCAT', [path_node, Arel::Nodes::Quoted.new('/%')])
    end

    private

    # Update `metadata_summary` for a collection of namespaces using a
    # single SQL statement constructed with Arel nodes. This method builds a
    # jsonb expression for each metadata field (via
    # `build_metadata_summary_update_sql`), expands the resulting jsonb into
    # key/value rows with `jsonb_each`, filters out non-positive values, and
    # aggregates back into a jsonb object which is then used in an
    # `UPDATE ... SET metadata_summary = <computed_jsonb>` performed via
    # `update_all` inside a transaction.
    #
    # Parameters:
    # - namespaces: an ActiveRecord::Relation of Namespace records to update.
    # - metadata_summary: Hash mapping metadata field => count.
    # - by_one: when true, treat every delta as 1 (used for simple increments/decrements).
    # - addition: when true apply addition, otherwise subtraction.
    #
    # Implementation notes / steps:
    # 1. Build per-field jsonb fragments and concatenate them into a single
    #    jsonb expression (`metadata_summary_update_sql`). This expression
    #    represents the changes to apply for the provided fields.
    # 2. Create a virtual table `entry` by calling `jsonb_each` on the
    #    concatenation of the existing `metadata_summary` and the update
    #    expression. `jsonb_each` expands the structure into (key, value)
    #    rows suitable for aggregation.
    # 3. Project a `jsonb_object_agg(key, value)` wrapped with `coalesce(..., '{}'::jsonb)`
    #    to ensure we always produce a jsonb object. Filter rows where the
    #    integer-cast value is > 0 so that zero/negative counts are excluded.
    # 4. Inside a transaction, acquire a FOR UPDATE lock on the target
    #    namespaces and call `update_all` with the grouped aggregation. This
    #    runs a single UPDATE statement for performance and avoids loading
    #    models into Ruby.
    #
    # Security / portability:
    # - The produced SQL is Postgres-specific (jsonb functions/operators).
    # - Field names are interpolated earlier when building fragments; ensure
    #   metadata field names originate from trusted application data.
    def update_metadata_summary_counts(namespaces, metadata_summary, by_one: false, addition: true) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      # Build the concatenated jsonb expression representing all per-field updates
      metadata_summary_update_sql = build_metadata_summary_update_sql(metadata_summary,
                                                                      addition ? Arel::Nodes::Addition : Arel::Nodes::Subtraction,
                                                                      by_one:)

      # Create a derived table `entry` by applying jsonb_each to the existing
      # metadata_summary concatenated with our update expression. This yields
      # rows of (key, value) for aggregation.
      entry_table = Arel::Table.new(
        Arel::Nodes::NamedFunction.new(
          'jsonb_each',
          [Namespace.arel_table[:metadata_summary].concat(metadata_summary_update_sql)]
        ),
        as: 'entry'
      )

      # Aggregate back the filtered key/value rows into a jsonb object and
      # ensure defaults to '{}'::jsonb when empty. Only include entries where
      # the integer-cast value is greater than zero.
      updated_metadata_summary = entry_table.project(
        Arel::Nodes::NamedFunction.new(
          'coalesce',
          [
            Arel::Nodes::NamedFunction.new('jsonb_object_agg', [entry_table[:key], entry_table[:value]]),
            Arel::Nodes::InfixOperation.new('::', Arel::Nodes::Quoted.new('{}'), Arel::Nodes::SqlLiteral.new('jsonb'))
          ]
        )
      ).where(Arel::Nodes::InfixOperation.new('::', entry_table[:value], Arel::Nodes::SqlLiteral.new('integer')).gt(0))

      root_namespace = if namespaces.one?
                         namespaces.first
                       else
                         namespaces.where(parent_id: nil).first
                       end

      # Perform the update inside a transaction using a PostgreSQL advisory lock
      # to avoid race conditions when multiple processes update the same
      # namespaces concurrently. Use update_all to run a single efficient SQL
      # UPDATE without instantiating ActiveRecord objects.
      Namespace.transaction do
        lock_id = Zlib.crc32("namespace_#{root_namespace.puid}_metadata_summary_lock").to_i
        Namespace.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

        namespaces.update_all(metadata_summary: Arel::Nodes::Grouping.new(updated_metadata_summary)) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    # Build a combined Arel SQL expression that represents an update to the
    # `metadata_summary` jsonb column for multiple metadata fields.
    #
    # The method delegates to `single_field_metadata_summary_jsonb` to build a
    # per-field jsonb fragment then concatenates those fragments with the jsonb
    # concatenation operator (`||`). The final result is wrapped in an
    # `Arel::Nodes::Grouping` so it can be used directly inside other Arel
    # expressions (for example, concatenating onto an existing jsonb value
    # before calling `jsonb_each`).
    #
    # Parameters:
    # - metadata_summary: a Hash mapping metadata field names (String) to their
    #   corresponding numeric counts (Integer). Example: { 'age' => 10, 'tag' => 3 }
    # - operation: an Arel node class used to combine the existing field value
    #   with the provided count (defaults to Arel::Nodes::Addition). Pass
    #   Arel::Nodes::Subtraction to decrement counts.
    # - by_one: when true, ignore the provided counts in the hash and use 1
    #   for every field. This is used when only incrementing/decrementing by one
    #   irrespective of the provided `metadata_summary` values.
    #
    # Returns:
    # - An Arel::Nodes::Grouping that contains SQL like
    #   `(<fragment1> || <fragment2> || ...)`, where each fragment is the
    #   `(concat(... )::jsonb)` representation for a single field. This node can
    #   be concatenated onto `Namespace.arel_table[:metadata_summary]` or
    #   otherwise embedded inside raw Arel SQL.
    #
    # Notes:
    # - The method uses `to_sql` on the per-field Arel nodes and joins them
    #   with a literal ` || ` string. This is intentional because Arel does not
    #   model the jsonb concatenation operator directly. The produced SQL is
    #   therefore Postgres-specific.
    # - Field names are interpolated into quoted fragments in the per-field
    #   builder; callers should ensure field names come from trusted sources.
    def build_metadata_summary_update_sql(metadata_summary, operation = Arel::Nodes::Addition, by_one: false)
      metadata_summary_update_sql = metadata_summary.map do |metadata_field, count|
        # If by_one is true we always use 1 as the per-field delta; otherwise
        # use the count provided in the metadata_summary hash.
        single_field_metadata_summary_jsonb(metadata_field, by_one ? 1 : count, operation)
      end

      # Join the generated fragments using the jsonb concatenation operator and
      # wrap in a Grouping so it can be embedded in other Arel nodes.
      Arel::Nodes::Grouping.new(Arel.sql(metadata_summary_update_sql.map(&:to_sql).join(' || ')))
    end

    # Build an Arel expression that returns a jsonb fragment for a single
    # metadata field. The resulting SQL is equivalent to:
    #
    #   (concat(
    #     '{',
    #     '"<field>": ',
    #     (coalesce((metadata_summary->>'<field>')::integer, 0) <op> <count>),
    #     '}'
    #   )::jsonb)
    #
    # This is used by `build_metadata_summary_update_sql` to produce pieces that
    # are concatenated (`||`) together into a full jsonb update expression.
    #
    # Parameters:
    # - metadata_field: String name of the metadata key stored inside the
    #   jsonb `metadata_summary` column. This value is interpolated into the
    #   produced SQL as a quoted fragment (caller must ensure the field name is
    #   a valid key in the JSON object).
    # - count: Integer or Arel expression representing the numeric delta to
    #   apply for this field.
    # - operation: An Arel node class (e.g. Arel::Nodes::Addition or
    #   Arel::Nodes::Subtraction) used to combine the existing integer value and
    #   `count`.
    #
    # Returns:
    # - An Arel node representing `(concat(... )::jsonb)` which can be joined
    #   with other fragments using the `||` operator to form a jsonb update.
    #
    # Notes / edge cases:
    # - The current value for the field is read with `->>` which returns text;
    #   it is cast to integer and wrapped with `coalesce(..., 0)` so missing or
    #   non-numeric values fall back to 0.
    # - The method returns an Arel::Nodes::InfixOperation for the final cast
    #   (`:: jsonb`) so callers can safely concatenate fragments.
    # - This method purposely constructs SQL fragments via Arel nodes because
    #   Postgres jsonb functions/operators are not directly modelled by Arel.
    def single_field_metadata_summary_jsonb(metadata_field, count, operation) # rubocop:disable Metrics/MethodLength
      Arel::Nodes::InfixOperation.new(
        '::',
        Arel::Nodes::NamedFunction.new(
          'concat', [
            # Begin JSON object fragment
            Arel::Nodes::Quoted.new('{'),
            # Insert the quoted field name and colon (e.g. "age": )
            Arel::Nodes::Quoted.new("\"#{metadata_field}\": "),
            # Compute (coalesce((metadata_summary->>'field')::integer, 0) <op> count)
            operation.new(
              Arel::Nodes::NamedFunction.new(
                'coalesce',
                [
                  Arel::Nodes::InfixOperation.new(
                    '::',
                    Arel::Nodes::Grouping.new(
                      Arel::Nodes::InfixOperation.new(
                        '->>', Namespace.arel_table[:metadata_summary], Arel::Nodes::Quoted.new(metadata_field)
                      )
                    ),
                    Arel::Nodes::SqlLiteral.new('integer')
                  ),
                  # Default to 0 when value is NULL or non-numeric
                  Arel::Nodes::SqlLiteral.new('0')
                ]
              ),
              count
            ),
            # Close JSON object fragment
            Arel::Nodes::Quoted.new('}')
          ]
        ), Arel::Nodes::SqlLiteral.new('jsonb')
      )
    end
  end

  def to_param
    full_path
  end

  def human_name
    full_name
  end

  def group_namespace?
    type == Group.sti_name
  end

  def project_namespace?
    type == Namespaces::ProjectNamespace.sti_name
  end

  def user_namespace?
    type == Namespaces::UserNamespace.sti_name
  end

  def owner_required?
    user_namespace? || project_namespace?
  end

  def has_parent? # rubocop:disable Naming/PredicatePrefix
    parent_id.present? || parent.present?
  end

  def children_allowed?
    return false if project_namespace?

    ancestors.count >= Namespace::MAX_ANCESTORS - 2
  end

  def children_of_type?(type)
    Namespace.exists?(parent: self, type:)
  end

  def children_of_type(type)
    Namespace.where(parent: self, type:)
  end

  def validate_type
    return unless type.nil?

    errors.add(:type, 'Namespace is not allowed to be directly created')
  end

  def validate_parent_type # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    unless has_parent?
      errors.add(:parent_id, 'must be set for a project namespace') if project_namespace?

      return
    end

    errors.add(:parent_id, 'project namespace cannot be the parent of another namespace') if parent&.project_namespace?

    if user_namespace?
      errors.add(:parent_id, 'cannot be used for user namespace')
    elsif group_namespace?
      errors.add(:parent_id, 'user namespace cannot be the parent of another namespace') if parent.user_namespace?
    end
  end

  def validate_nesting_level
    return unless has_parent? && (parent.ancestors.count + 1) > MAX_ANCESTORS - 1

    errors.add(:parent_id, :nesting_level_too_deep)
  end

  # self = namespace receiving transferred_namespace
  # old_namespace = the old namespace transferred_namespace originated from
  def update_metadata_summary_by_namespace_transfer(transferred_namespace, old_namespace)
    metadata_to_update = transferred_namespace.metadata_summary
    return if metadata_to_update.empty?

    unless old_namespace.nil? || old_namespace.type == Namespaces::UserNamespace.sti_name
      Namespace.subtract_from_metadata_summary_count(old_namespace.self_and_ancestors, metadata_to_update, false)
    end

    return unless type != Namespaces::UserNamespace.sti_name

    Namespace.add_to_metadata_summary_count(self_and_ancestors, metadata_to_update, false)
  end

  def update_metadata_summary_by_namespace_deletion
    return if metadata_summary.empty?

    Namespace.subtract_from_metadata_summary_count(parent.self_and_ancestors, metadata_summary, false)
  end

  def self.model_prefix
    raise NotImplementedError, 'The underlying class should implement this method to set the model prefix.'
  end

  def metadata_fields
    metadata_summary.keys.sort
  end

  def metadata_templates
    MetadataTemplate.where(namespace: self)
  end

  private

  # Method to restore namespace routes when the namespace is restored
  def restore_routes
    Route.restore(Route.only_deleted.find_by(source_id: id)&.id, recursive: true)
  end
end

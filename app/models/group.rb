# frozen_string_literal: true

# Namespace for Groups
class Group < Namespace # rubocop:disable Metrics/ClassLength
  include History

  has_many :group_members, foreign_key: :namespace_id, inverse_of: :group,
                           class_name: 'Member', dependent: :destroy
  has_many :project_namespaces,
           lambda {
             where(type: Namespaces::ProjectNamespace.sti_name)
           },
           class_name: 'Namespace', foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :users, through: :group_members

  has_many :namespace_bots, foreign_key: :namespace_id, inverse_of: :namespace,
                            class_name: 'NamespaceBot', dependent: :destroy

  has_many :bots, through: :namespace_bots, source: :user

  has_many :shared_group_links, # rubocop:disable Rails/InverseOf
           lambda {
             where(namespace_type: Group.sti_name)
           },
           foreign_key: :group_id, class_name: 'NamespaceGroupLink', dependent: :destroy
  has_many :shared_project_namespace_links, # rubocop:disable Rails/InverseOf
           lambda {
             where(namespace_type: Namespaces::ProjectNamespace.sti_name)
           },
           foreign_key: :group_id, class_name: 'NamespaceGroupLink', dependent: :destroy

  has_many :shared_namespace_links, class_name: 'NamespaceGroupLink', dependent: :destroy

  has_many :shared_with_group_links, # rubocop:disable Rails/InverseOf
           lambda {
             where(namespace_type: Group.sti_name)
           },
           foreign_key: :namespace_id, class_name: 'NamespaceGroupLink',
           dependent: :destroy do
    def of_ancestors
      group = proxy_association.owner

      return NamespaceGroupLink.none unless group.has_parent?

      NamespaceGroupLink.where(namespace_id: group.ancestor_ids)
    end

    def of_ancestors_and_self
      group = proxy_association.owner

      source_ids = group.self_and_ancestor_ids

      NamespaceGroupLink.where(namespace_id: source_ids)
    end
  end

  has_many :shared_groups, through: :shared_group_links, source: :namespace
  has_many :shared_project_namespaces, through: :shared_project_namespace_links,
                                       class_name: 'Namespaces::ProjectNamespace', source: :namespace
  has_many :shared_namespaces, through: :shared_namespace_links, source: :namespace
  has_many :active_shared_namespaces, -> { not_expired }, through: :shared_namespace_links, source: :namespace
  has_many :shared_projects, through: :shared_project_namespaces, class_name: 'Project', source: :project
  has_many :shared_with_groups, through: :shared_with_group_links, source: :group

  validate :validate_public_namespace_type, if: -> { public_changed? || parent_id_changed? }

  def self.sti_name
    'Group'
  end

  def self.model_prefix
    'GRP'
  end

  def self.icon
    :squares_four
  end

  def metadata_fields
    metadata_fields = metadata_summary.keys

    # add metadata fields from shared namespaces
    metadata_fields.concat(
      Namespace
      .where(
        id: NamespaceGroupLink
            .not_expired
            .with_access
            .where(
              group_id: self_and_descendant_ids
            ).select(:namespace_id)
      ).pluck(:metadata_summary).map(&:keys).reduce(:+) || []
    )

    metadata_fields.sort.uniq
  end

  def aggregated_samples_count
    active_shared_namespaces = Namespace
                               .where(
                                 id: NamespaceGroupLink
                                     .not_expired
                                     .with_access
                                     .where(group_id: self_and_descendant_ids)
                                     .select(:namespace_id)
                               ).self_and_descendants.where(type: [Namespaces::ProjectNamespace.sti_name])
                               .where.not(id: self_and_descendants_of_type([Namespaces::ProjectNamespace.sti_name]).ids)

    samples_count + Project.where(namespace_id: active_shared_namespaces.select(:id)).sum(:samples_count)
  end

  def retrieve_group_activity
    PublicActivity::Activity.where(
      trackable_id: id,
      trackable_type: 'Namespace'
    )
  end

  def has_samples? # rubocop:disable Naming/PredicatePrefix
    samples_count.positive? || aggregated_samples_count.positive?
  end

  def add_to_samples_count(namespaces, addition_amount)
    namespaces.each do |namespace|
      Group.increment_counter(:samples_count, namespace.id, by: addition_amount) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def subtract_from_samples_count(namespaces, subtraction_amount)
    namespaces.each do |namespace|
      Group.decrement_counter(:samples_count, namespace.id, by: subtraction_amount) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # Delegates to namespace helper to propagate negative sample count changes through group ancestors.
  def update_samples_count_by_destroy_service(deleted_samples_count)
    propagate_samples_count_delta(-deleted_samples_count)
  end

  def validate_public_namespace_type
    return true if parent.nil?
    return true if parent.public == public

    errors.add(:public, :invalid)
  end
end

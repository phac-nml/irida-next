# frozen_string_literal: true

# Policy for projects authorization
class ProjectPolicy < NamespacePolicy # rubocop:disable Metrics/ClassLength
  pre_check :check_project_archived,
            except: %i[activity? destroy? view_history? new? read? sample_listing? read_sample?
                       view_attachments?]

  def effective_access_level # rubocop:disable Metrics/CyclomaticComplexity
    return unless record.instance_of?(Project)

    parent_namespace = record&.namespace&.parent
    @access_level = Member::AccessLevel::OWNER if parent_namespace&.user_namespace? && parent_namespace&.owner == user

    @access_level ||= Member.effective_access_level(record.namespace, user)
    @access_level
  end

  def token_active?(access_level)
    return false unless access_level == Member::AccessLevel::UPLOADER

    return false if Current.token.nil?

    Current.token.active?
  end

  def activity?
    if effective_access_level > Member::AccessLevel::NO_ACCESS &&
       effective_access_level != Member::AccessLevel::UPLOADER
      return true
    end

    details[:name] = record.name
    false
  end

  def view_history?
    if effective_access_level > Member::AccessLevel::NO_ACCESS &&
       effective_access_level != Member::AccessLevel::UPLOADER
      return true
    end

    details[:name] = record.name
    false
  end

  def destroy?
    return true if effective_access_level == Member::AccessLevel::OWNER

    details[:name] = record.name
    false
  end

  def edit?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def new?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.namespace.parent.name

    false
  end

  def read?
    if (effective_access_level > Member::AccessLevel::NO_ACCESS) &&
       effective_access_level != Member::AccessLevel::UPLOADER
      return true
    end
    return true if token_active?(effective_access_level) == true

    details[:name] = record.name
    false
  end

  def transfer?
    return true if effective_access_level == Member::AccessLevel::OWNER

    details[:name] = record.name
    false
  end

  def update?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def sample_listing?
    if effective_access_level > Member::AccessLevel::NO_ACCESS &&
       effective_access_level != Member::AccessLevel::UPLOADER
      return true
    end

    details[:name] = record.name
    false
  end

  def create_sample?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)
    return true if token_active?(effective_access_level) == true

    details[:name] = record.name
    false
  end

  def destroy_sample?
    return true if effective_access_level == Member::AccessLevel::OWNER

    details[:name] = record.name
    false
  end

  def read_sample?
    if effective_access_level > Member::AccessLevel::NO_ACCESS &&
       effective_access_level != Member::AccessLevel::UPLOADER
      return true
    end
    return true if token_active?(effective_access_level) == true

    details[:name] = record.name
    false
  end

  def update_sample?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)
    return true if token_active?(effective_access_level) == true

    details[:name] = record.name
    false
  end

  def transfer_sample?
    return false if record.namespace.parent.user_namespace? && effective_access_level != Member::AccessLevel::OWNER
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def transfer_sample_into_project?
    return true if effective_access_level == Member::AccessLevel::MAINTAINER &&
                   Member::AccessLevel.manageable.include?(
                     effective_access_level
                   )

    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name

    false
  end

  def clone_sample?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def clone_sample_into_project?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def export_data?
    return true if effective_access_level >= Member::AccessLevel::ANALYST

    details[:name] = record.name
    false
  end

  def submit_workflow?
    return true if effective_access_level >= Member::AccessLevel::ANALYST

    details[:name] = record.name
    false
  end

  def view_attachments?
    return true if effective_access_level >= Member::AccessLevel::ANALYST

    details[:name] = record.name
    false
  end

  def create_attachment?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)
    return true if token_active?(effective_access_level) == true

    details[:name] = record.name
    false
  end

  def destroy_attachment?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  scope_for :relation do |relation, options = {}| # rubocop:disable Metrics/BlockLength
    access_level = if options.key?(:access_level)
                     options[:access_level]
                   else
                     Member::AccessLevel.all_values_with_owner
                                        .filter { |level| level != Member::AccessLevel::NO_ACCESS }
                   end

    relation
      .with(
        # 1. Accessible namespace IDs for the user based on their memberships
        accessible_namespace_ids: Namespace
          .where(id: user.members.not_expired.with_access_level(access_level).select(:namespace_id))
          .self_and_descendant_ids,

        # 2. User's personal project namespaces
        personal_project_namespaces: Namespaces::ProjectNamespace
          .not_archived
          .where(parent_id: user.namespace&.id)
          .select(:id),

        # 3. Direct project namespaces the user has access to
        direct_project_namespaces: Namespaces::ProjectNamespace
          .not_archived
          .where(Arel.sql('id IN (SELECT id FROM accessible_namespace_ids)'))
          .select(:id),

        # 4. Project namespaces the user has access to through groups
        group_project_namespaces: Namespaces::ProjectNamespace
          .not_archived
          .where(Arel.sql('parent_id IN (SELECT id FROM accessible_namespace_ids)'))
          .select(:id),

        # 5. Accessible linked namespaces for the user based on group links
        accessible_linked_namespace_ids: Namespace
          .where(id: NamespaceGroupLink
            .not_expired
            .where(Arel.sql('group_id IN (SELECT id FROM accessible_namespace_ids)'))
            .with_group_access_level(access_level)
            .select(:namespace_id))
          .self_and_descendant_ids,

        # 6. Directly linked project namespaces the user has access to
        direct_linked_project_namespaces: Namespaces::ProjectNamespace
          .not_archived
          .where(Arel.sql('id IN (SELECT id FROM accessible_linked_namespace_ids)'))
          .select(:id),

        # 7. Project namespaces linked through accessible linked namespaces
        group_linked_project_namespaces: Namespaces::ProjectNamespace
          .not_archived
          .where(Arel.sql('parent_id IN (SELECT id FROM accessible_linked_namespace_ids)'))
          .select(:id),

        # 8. Public project namespaces
        public_project_namespaces:
          if access_level.include?(Member::AccessLevel::GUEST)
            Namespaces::ProjectNamespace
              .not_archived
              .where(public: true)
              .select(:id)
          else
            Namespaces::ProjectNamespace.none.select(:id)
          end
      ).where(
        Arel.sql(
          'projects.namespace_id IN (
            SELECT id FROM personal_project_namespaces
            UNION ALL
            SELECT id FROM direct_project_namespaces
            UNION ALL
            SELECT id FROM group_project_namespaces
            UNION ALL
            SELECT id FROM group_linked_project_namespaces
            UNION ALL
            SELECT id FROM direct_linked_project_namespaces
            UNION ALL
            SELECT id FROM public_project_namespaces
          )'
        )
      ).include_route
  end

  scope_for :relation, :archived_projects do |relation| # rubocop:disable Metrics/BlockLength
    access_level = Member::AccessLevel.all_values_with_owner.filter { |level| level != Member::AccessLevel::NO_ACCESS }

    relation
      .with(
        # 1. Accessible namespace IDs for the user based on their memberships
        accessible_namespace_ids: Namespace
          .where(id: user.members.not_expired.with_access_level(access_level).select(:namespace_id))
          .self_and_descendant_ids,

        # 2. User's personal project namespaces
        personal_project_namespaces: Namespaces::ProjectNamespace
          .archived
          .where(parent_id: user.namespace&.id)
          .select(:id),

        # 3. Direct project namespaces the user has access to
        direct_project_namespaces: Namespaces::ProjectNamespace
          .archived
          .where(Arel.sql('id IN (SELECT id FROM accessible_namespace_ids)'))
          .select(:id),

        # 4. Project namespaces the user has access to through groups
        group_project_namespaces: Namespaces::ProjectNamespace
          .archived
          .where(Arel.sql('parent_id IN (SELECT id FROM accessible_namespace_ids)'))
          .select(:id),

        # 5. Accessible linked namespaces for the user based on group links
        accessible_linked_namespace_ids: Namespace
          .where(id: NamespaceGroupLink
            .not_expired
            .with_group_access_level(access_level)
            .where(Arel.sql('group_id IN (SELECT id FROM accessible_namespace_ids)'))
            .select(:namespace_id))
          .self_and_descendant_ids,

        # 6. Directly linked project namespaces the user has access to
        direct_linked_project_namespaces: Namespaces::ProjectNamespace
          .archived
          .where(Arel.sql('id IN (SELECT id FROM accessible_linked_namespace_ids)'))
          .select(:id),

        # 7. Project namespaces linked through accessible linked namespaces
        group_linked_project_namespaces: Namespaces::ProjectNamespace
          .archived
          .where(Arel.sql('parent_id IN (SELECT id FROM accessible_linked_namespace_ids)'))
          .select(:id),

        # 8. Public project namespaces
        public_project_namespaces:
          if access_level.include?(Member::AccessLevel::GUEST)
            Namespaces::ProjectNamespace
              .archived
              .where(public: true)
              .select(:id)
          else
            Namespaces::ProjectNamespace.none.select(:id)
          end
      ).where(
        Arel.sql(
          'projects.namespace_id IN (
            SELECT id FROM personal_project_namespaces
            UNION ALL
            SELECT id FROM direct_project_namespaces
            UNION ALL
            SELECT id FROM group_project_namespaces
            UNION ALL
            SELECT id FROM group_linked_project_namespaces
            UNION ALL
            SELECT id FROM direct_linked_project_namespaces
            UNION ALL
            SELECT id FROM public_project_namespaces
          )'
        )
      ).include_route
  end

  scope_for :relation, :project_samples_transferable do |relation, options|
    obj = options.key?(:group) ? options[:group] : options[:project]
    if Member.effective_access_level(obj, user) == Member::AccessLevel::MAINTAINER
      return relation.none if obj.project_namespace? && obj.parent.user_namespace?

      top_level_ancestor = if obj.project_namespace?
                             obj.parent.self_and_ancestors.find_by(type: Group.sti_name, parent: nil)
                           else
                             obj.self_and_ancestors.find_by(type: Group.sti_name, parent: nil)
                           end

      group_and_subgroup_ids = top_level_ancestor.self_and_descendant_ids

      authorized_scope(relation, type: :relation,
                                 as: :manageable_without_shared_links)
        .where(namespace: { parent_id: group_and_subgroup_ids })

    else
      authorized_scope(relation, type: :relation, as: :manageable)
    end
  end

  scope_for :relation, :manageable_without_shared_links do |relation|
    relation.with(
      direct_project_namespaces: Namespaces::ProjectNamespace.not_archived.where(
        id: user.members.not_expired.where(access_level: Member::AccessLevel.manageable).select(:namespace_id)
      ),
      group_project_namespaces: Namespaces::ProjectNamespace.not_archived.where(parent: Namespace.where(id:
        user.members.not_expired.joins(:namespace).where(
          namespace_id: user.groups.self_and_descendants,
          access_level: Member::AccessLevel.manageable,
          namespace: { type: Group.sti_name }
        ).select(:namespace_id), type: Group.sti_name).self_and_descendant_ids).select(:id)
    ).where(
      Arel.sql(
        'projects.namespace_id in (
          SELECT namespace_id FROM direct_project_namespaces
          UNION ALL
          SELECT id FROM group_project_namespaces
        )'
      )
    ).include_route
  end

  scope_for :relation, :manageable do |relation|
    authorized_scope(relation, type: :relation, scope_options: { access_level: Member::AccessLevel.manageable })
  end

  scope_for :relation, :personal do |relation|
    relation
      .with(
        personal_project_namespaces: Namespaces::ProjectNamespace.not_archived.where(parent_id: user.namespace&.id)
      )
      .where(
        Arel.sql(
          'projects.namespace_id in (select id from personal_project_namespaces)'
        )
      ).include_route
  end

  scope_for :relation, :group_projects do |relation, options| # rubocop:disable Metrics/BlockLength
    group = options[:group]
    minimum_access_level = if options.key?(:minimum_access_level)
                             options[:minimum_access_level]
                           else
                             Member::AccessLevel::GUEST
                           end

    next relation.none unless Member.effective_access_level(group, user) >= minimum_access_level

    relation
      .with(
        direct_group_project_namespaces: Namespaces::ProjectNamespace.not_archived.where(
          parent_id: group.self_and_descendants.select(:id)
        ).select(:id),
        linked_group_project_namespaces: Namespace.where(
          id: NamespaceGroupLink
              .not_expired
              .where(group_id: group.self_and_descendant_ids, group_access_level: minimum_access_level..)
              .select(:namespace_id)
        ).self_and_descendants.where(type: Namespaces::ProjectNamespace.sti_name, archived_at: nil).select(:id)
      ).where(
        Arel.sql(
          'namespace_id IN (
            SELECT id FROM direct_group_project_namespaces
            UNION ALL
            SELECT id FROM linked_group_project_namespaces
          )'
        )
      )
  end

  private

  def check_project_archived
    deny! if record.namespace.archived?
  end
end

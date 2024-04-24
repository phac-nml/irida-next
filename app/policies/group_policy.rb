# frozen_string_literal: true

# Policy for groups authorization
class GroupPolicy < NamespacePolicy # rubocop:disable Metrics/ClassLength
  def create?
    return true if Member.can_create?(user, record) == true

    details[:name] = record.name
    false
  end

  def create_subgroup?
    return true if Member.can_create?(user, record) == true

    details[:name] = record.name
    false
  end

  def view_history?
    return true if Member.can_view?(user, record, false) == true

    details[:name] = record.name
    false
  end

  def destroy?
    return true if Member.can_destroy?(user, record) == true

    details[:name] = record.name
    false
  end

  def edit?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def new?
    return true if Member.can_create?(user, record) == true

    details[:name] = record.name
    false
  end

  def read?
    return true if Member.can_view?(user, record) == true

    details[:name] = record.name
    false
  end

  def transfer?
    return true if Member.can_transfer?(user, record)

    details[:name] = record.name
    false
  end

  def transfer_into_namespace?
    return true if Member.can_transfer_into_namespace?(user, record) == true

    details[:name] = record.name
    false
  end

  def update?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def member_listing?
    return true if Member.can_view?(user, record) == true

    details[:name] = record.name
    false
  end

  def create_member?
    return true if Member.can_create?(user, record) == true

    details[:name] = record.name
    false
  end

  def destroy_member?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def update_member?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def sample_listing?
    return true if Member.can_view?(user, record) == true

    details[:name] = record.name
    false
  end

  def link_namespace_with_group?
    return true if Member.can_link_namespace_to_group?(user, record) == true

    details[:name] = record.name
    false
  end

  def unlink_namespace_with_group?
    return true if Member.can_unlink_namespace_from_group?(user, record) == true

    details[:name] = record.name
    false
  end

  def update_namespace_with_group_link?
    return true if Member.can_update_namespace_with_group_link?(user, record) == true

    details[:name] = record.name
    false
  end

  def submit_workflow?
    return true if Member.can_submit_workflow?(user, record) == true

    details[:name] = record.name
    false
  end

  def export_sample_data?
    return true if Member.can_export_data?(user, record) == true

    details[:name] = record.name
    false
  end

  def create_bot_accounts?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def destroy_bot_accounts?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def view_bot_accounts?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def view_bot_personal_access_tokens?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def generate_bot_personal_access_token?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def revoke_bot_personal_access_token?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  scope_for :relation do |relation|
    relation.with(
      user_groups: relation.where(id: user.members.not_expired.select(:namespace_id)).self_and_descendant_ids
      .where(type: Group.sti_name),
      linked_groups: NamespaceGroupLink.where(Arel.sql('namespace_group_links.group_id in (select * from user_groups)'))
      .select(:namespace_id)
    ).where(
      Arel.sql(
        'namespaces.id in (select * from user_groups)
        or namespaces.id in (select * from linked_groups)'
      )
    )
  end
end

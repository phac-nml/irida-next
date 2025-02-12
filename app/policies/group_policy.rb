# frozen_string_literal: true

# Policy for groups authorization
class GroupPolicy < NamespacePolicy # rubocop:disable Metrics/ClassLength
  def effective_access_level
    return unless record.instance_of?(Group)

    @access_level ||= Member.effective_access_level(record, user)
    @access_level
  end

  def token_active(access_level)
    return false unless access_level == Member::AccessLevel::UPLOADER

    return false if Current.token&.nil?

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

  def create?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def create_subgroup?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

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

    details[:name] = record.name
    false
  end

  def read?
    if effective_access_level > Member::AccessLevel::NO_ACCESS &&
       effective_access_level != Member::AccessLevel::UPLOADER
      return true
    end
    return true if token_active(effective_access_level) == true

    details[:name] = record.name
    false
  end

  def transfer?
    return true if effective_access_level == Member::AccessLevel::OWNER

    details[:name] = record.name
    false
  end

  def transfer_into_namespace?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def update?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def member_listing?
    if effective_access_level > Member::AccessLevel::NO_ACCESS &&
       effective_access_level != Member::AccessLevel::UPLOADER
      return true
    end

    details[:name] = record.name
    false
  end

  def create_member?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def destroy_member?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def update_member?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def sample_listing?
    if effective_access_level > Member::AccessLevel::NO_ACCESS &&
       effective_access_level != Member::AccessLevel::UPLOADER
      return true
    end
    return true if token_active(effective_access_level) == true

    details[:name] = record.name
    false
  end

  def link_namespace_with_group?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def unlink_namespace_with_group?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def update_namespace_with_group_link?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def submit_workflow?
    return true if effective_access_level >= Member::AccessLevel::ANALYST

    details[:name] = record.name
    false
  end

  def view_workflow_executions?
    return true if effective_access_level >= Member::AccessLevel::ANALYST

    details[:name] = record.name
    false
  end

  def export_data?
    return true if effective_access_level >= Member::AccessLevel::ANALYST

    details[:name] = record.name
    false
  end

  def create_bot_accounts?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def destroy_bot_accounts?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def view_bot_accounts?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def view_bot_personal_access_tokens?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def generate_bot_personal_access_token?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def revoke_bot_personal_access_token?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def update_sample_metadata?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def import_samples_and_metadata?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

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
    return true if token_active(effective_access_level) == true

    details[:name] = record.name
    false
  end

  def destroy_attachment?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)
    return true if token_active(effective_access_level) == true

    details[:name] = record.name
    false
  end

  def create_metadata_templates?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def destroy_metadata_templates?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def update_metadata_templates?
    return true if Member::AccessLevel.manageable.include?(effective_access_level)

    details[:name] = record.name
    false
  end

  def view_metadata_templates?
    return true if effective_access_level >= Member::AccessLevel::GUEST

    details[:name] = record.name
    false
  end

  scope_for :relation do |relation|
    relation.with(
      user_groups: relation.where(id: user.members.not_expired.select(:namespace_id)).self_and_descendant_ids,
      linked_groups: relation.where(id: NamespaceGroupLink.not_expired
      .where(Arel.sql('namespace_group_links.group_id in (select * from user_groups)')).select(:namespace_id))
      .self_and_descendant_ids
    ).where(
      Arel.sql(
        'namespaces.id in (select * from user_groups)
        or namespaces.id in (select * from linked_groups)'
      )
    )
  end
end

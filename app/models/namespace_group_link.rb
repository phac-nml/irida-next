# frozen_string_literal: true

# entity class for NamespaceGroupLink
class NamespaceGroupLink < ApplicationRecord
  has_logidze
  acts_as_paranoid

  before_validation :set_namespace_type

  belongs_to :group, class_name: 'Group'
  belongs_to :namespace, class_name: 'Namespace'

  validates :group_id, uniqueness: { scope: [:namespace_id] }

  validates :group_access_level, inclusion: { in: Member::AccessLevel.all_values_with_owner },
                                 presence: true

  validates :namespace_type,
            inclusion: {
              in: [Group.sti_name, Namespaces::ProjectNamespace.sti_name]
            }

  after_destroy :send_access_revoked_email
  after_save :send_access_granted_email, if: :previously_new_record?

  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.zone.now.beginning_of_day) }
  scope :for_namespace_and_ancestors, lambda { |namespace = nil|
                                        where(namespace:).or(where(namespace: namespace.parent&.self_and_ancestors))
                                      }

  def send_access_revoked_email
    memberships = Member.where(namespace: group).not_expired
    memberships.each do |member|
      next if Member.can_view?(member.user, namespace, true)

      MemberMailer.access_revoked_email(member, manager_emails, namespace).deliver_later
    end
  end

  def send_access_granted_email
    memberships = Member.where(namespace: group).not_expired
    memberships.each do |member|
      next unless Member.can_view?(member.user, namespace, true)

      MemberMailer.access_granted_email(member, manager_emails, namespace).deliver_later
    end
  end

  def manager_emails
    manager_memberships = Member.for_namespace_and_ancestors(group).not_expired
                                .where(access_level: Member::AccessLevel.manageable)
    managers = User.where(id: manager_memberships.select(:user_id)).distinct
    managers.pluck(:email)
  end

  private

  def set_namespace_type
    return unless namespace

    self.namespace_type = namespace.type
  end
end

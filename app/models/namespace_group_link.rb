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

  after_destroy :send_access_revoked_emails
  after_save :send_access_granted_emails, if: :previously_new_record?

  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.zone.now.beginning_of_day) }
  scope :for_namespace_and_ancestors, lambda { |namespace = nil|
                                        where(namespace:).or(where(namespace: namespace.parent&.self_and_ancestors))
                                      }

  def send_access_revoked_emails
    I18n.available_locales.each do |locale|
      user_emails = Member.user_emails(group, locale)
      unless user_emails.empty?
        GroupLinkMailer.access_revoked_user_email(user_emails, group, namespace, locale).deliver_later
      end

      manager_emails = Member.manager_emails(namespace, locale)
      next if manager_emails.empty?

      GroupLinkMailer.access_revoked_manager_email(manager_emails, group, namespace, locale).deliver_later
    end
  end

  def send_access_granted_emails
    I18n.available_locales.each do |locale|
      user_emails = Member.user_emails(group, locale)
      unless user_emails.empty?
        GroupLinkMailer.access_granted_user_email(user_emails, group, namespace, locale).deliver_later
      end

      manager_emails = Member.manager_emails(namespace, locale)
      next if manager_emails.empty?

      GroupLinkMailer.access_granted_manager_email(manager_emails, group, namespace, locale).deliver_later
    end
  end

  private

  def set_namespace_type
    return unless namespace

    self.namespace_type = namespace.type
  end
end

# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/member_mailer
class MemberMailerPreview < ActionMailer::Preview
  def access_granted_to_group_user_email
    setup_group
    MemberMailer.access_granted_user_email(@member, @namespace)
  end

  def access_granted_to_project_user_email
    setup_project
    MemberMailer.access_granted_user_email(@member, @namespace)
  end

  def access_revoked_from_group_user_email
    setup_group
    MemberMailer.access_revoked_user_email(@member, @namespace)
  end

  def access_revoked_from_project_user_email
    setup_project
    MemberMailer.access_revoked_user_email(@member, @namespace)
  end

  def access_granted_to_group_manager_email
    setup_group
    MemberMailer.access_granted_manager_email(@member, @manager_emails, @namespace, params[:locale])
  end

  def access_granted_to_project_manager_email
    setup_project
    MemberMailer.access_granted_manager_email(@member, @manager_emails, @namespace, params[:locale])
  end

  def access_revoked_from_group_manager_email
    setup_group
    MemberMailer.access_revoked_manager_email(@member, @manager_emails, @namespace, params[:locale])
  end

  def access_revoked_from_project_manager_email
    setup_project
    MemberMailer.access_revoked_manager_email(@member, @manager_emails, @namespace, params[:locale])
  end

  private

  def setup_group
    @namespace = Group.first
    setup
  end

  def setup_project
    @namespace = Project.first.namespace
    setup
  end

  def setup
    @member = Member.first
    @member.user.locale = params[:locale]
    @manager_emails = Member.manager_emails(@namespace, @member)
  end
end

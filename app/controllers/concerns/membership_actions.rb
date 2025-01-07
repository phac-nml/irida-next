# frozen_string_literal: true

# Common Members actions
module MembershipActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { member }, only: %i[destroy update]
    before_action proc { available_users }, only: %i[new create]
    before_action proc { access_levels }
    before_action proc { context_crumbs }, only: %i[index new]
    before_action proc { tab }, only: %i[index new create]
  end

  def index
    authorize! @namespace, to: :member_listing?
    @q = load_members.ransack(params[:q])
    set_default_sort
    @pagy, @members = pagy(@q.result)
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    authorize! @namespace, to: :create_member? unless @namespace.parent.nil? && @namespace.owner == current_user
    @new_member = Member.new(namespace_id: @namespace.id)

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def create # rubocop:disable Metrics/MethodLength
    @new_member = Members::CreateService.new(current_user, @namespace, member_params, true).execute

    if @new_member.persisted?
      respond_to do |format|
        format.turbo_stream do
          render status: :ok, locals: { member: @new_member, type: 'success',
                                        message: t('concerns.membership_actions.create.success',
                                                   user: @new_member.user.email) }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render status: :unprocessable_entity, locals: { member: @new_member, type: 'alert',
                                                          message: error_message(@new_member) }
        end
      end
    end
  end

  def destroy # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
    Members::DestroyService.new(@member, @namespace, current_user).execute

    if @member.deleted?
      if current_user == @member.user
        flash[:success] = t('concerns.membership_actions.destroy.leave_success', name: @namespace.name)
        if @namespace.group_namespace?
          redirect_to dashboard_groups_path(format: :html)
        else
          redirect_to dashboard_projects_path(format: :html)
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render status: :ok, locals: { member: @member, type: 'success',
                                          message: t('concerns.membership_actions.destroy.success',
                                                     user: @member.user.email) }
          end
        end
      end
    else
      message = if @member.user == current_user
                  I18n.t('activerecord.errors.models.member.destroy.last_member_self',
                         namespace_type: @namespace.class.model_name.human)
                else
                  error_message(@member)
                end

      respond_to do |format|
        format.turbo_stream do
          render status: :unprocessable_entity, locals: { member: @member, type: 'alert',
                                                          message: }
        end
      end
    end
  end

  def update # rubocop:disable Metrics/MethodLength
    updated = Members::UpdateService.new(@member, @namespace, current_user, member_params).execute
    respond_to do |format|
      if updated
        format.turbo_stream do
          render status: :ok, locals: { member: @member, access_levels: @access_levels, type: 'success',
                                        message: t('concerns.membership_actions.update.success',
                                                   user_email: @member.user.email) }
        end
      else
        format.turbo_stream do
          render status: :bad_request,
                 locals: { member: @member, type: 'alert',
                           message: error_message(@member) }
        end
      end
    end
  end

  private

  def access_levels
    @access_levels = Member::AccessLevel.access_level_options_for_user(@namespace, current_user)
  end

  def available_users
    # Remove current user from available users as a user cannot add themselves
    available_users = User.human_users.where.not(id: Member.select(:user_id).where(namespace: @namespace))
                          .where.not(id: current_user.id)

    @available_users = User.where(id: available_users.select(:id) + available_bots.select(:id)).order(:email)
  end

  def available_bots # rubocop:disable Metrics/AbcSize
    if @namespace.type == Namespaces::ProjectNamespace.sti_name
      @namespace.bots.without_automation_bots.where.not(
        id: Member.select(:user_id).where(namespace: @namespace)
      ).or(
        User.bots.without_automation_bots.where(user_type: User.user_types[:group_bot])
            .where.not(id: Member.select(:user_id).where(namespace: @namespace))
      )
    elsif @namespace.type == Group.sti_name
      User.bots.without_automation_bots.where(user_type: User.user_types[:group_bot])
          .where.not(id: Member.select(:user_id).where(namespace: @namespace))
    else
      User.none
    end
  end

  def load_members
    authorized_scope(Member, type: :relation, scope_options: { namespace: @namespace })
  end

  def tab
    @tab = params[:tab]
  end

  def set_default_sort
    @q.sorts = 'user_email asc' if @q.sorts.empty?
  end

  protected

  def members_path
    raise NotImplementedError
  end

  def member_namespace
    raise NotImplementedError
  end

  def authorize_view_members
    raise NotImplementedError
  end

  def authorize_modify_members
    raise NotImplementedError
  end
end

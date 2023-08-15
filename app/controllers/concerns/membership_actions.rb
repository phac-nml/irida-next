# frozen_string_literal: true

# Common Members actions
module MembershipActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern
  include ShareActions

  included do
    before_action proc { namespace }
    before_action proc { member }, only: %i[destroy update]
    before_action proc { available_users }, only: %i[new create]
    before_action proc { access_levels }, only: %i[new create index update invite_group invited_groups]
    before_action proc { context_crumbs }, only: %i[index new]
  end

  def index
    authorize! @namespace, to: :member_listing?
    @pagy, @members = pagy(load_members)
  end

  def new
    authorize! @namespace, to: :create_member? unless @namespace.parent.nil? && @namespace.owner == current_user
    @new_member = Member.new(namespace_id: @namespace.id)

    respond_to do |format|
      format.html do
        render 'new'
      end
    end
  end

  def create
    @new_member = Members::CreateService.new(current_user, @namespace, member_params).execute

    if @new_member.persisted?
      flash[:success] = t('.success')
      redirect_to members_path
    else
      render :new, status: :unprocessable_entity, locals: { member: @new_member }
    end
  end

  def destroy # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    Members::DestroyService.new(@member, @namespace, current_user).execute

    if @member.deleted?
      if current_user == @member.user
        flash[:success] = t('.leave_success', name: @namespace.name)
        redirect_to root_path(format: :html)
      else
        respond_to do |format|
          format.turbo_stream do
            render status: :ok, locals: { member: @member, type: 'success',
                                          message: t('.success', user: @member.user.email) }
          end
        end
      end
    else
<<<<<<< HEAD
      flash[:error] = @member.errors.full_messages.first if @member.user != current_user
      if @member.user == current_user
        flash[:error] = I18n.t('activerecord.errors.models.member.destroy.last_member_self',
                               namespace_type: @namespace.class.model_name.human)
=======
      message = if @member.user == current_user
                  I18n.t('activerecord.errors.models.member.destroy.last_member_self',
                         namespace_type: @namespace.class.model_name.human)
                else
                  @member.errors.full_messages.first
                end

      respond_to do |format|
        format.turbo_stream do
          render status: :unprocessable_entity, locals: { member: @member, type: 'alert',
                                                          message: }
        end
>>>>>>> 5f9986ce (Updated member removal to be done via turbo_stream, updated tests)
      end
    end
  end

  def update
    updated = Members::UpdateService.new(@member, @namespace, current_user, member_params).execute
    respond_to do |format|
      if updated
        format.turbo_stream do
          render status: :ok, locals: { member: @member, access_levels: @access_levels, type: 'success',
                                        message: t('.success', user_email: @member.user.email) }
        end
      else
        format.turbo_stream do
          render status: :bad_request,
                 locals: { member: @member, type: 'alert',
                           message: @member.errors.full_messages.first }
        end
      end
    end
  end

  def invite_group; end

  def invited_groups; end

  private

  def access_levels
    @access_levels = Member::AccessLevel.access_level_options_for_user(@namespace, current_user)
  end

  def available_users
    # Remove current user from available users as a user cannot add themselves
    @available_users = User.where.not(id: Member.select(:user_id).where(namespace: @namespace))
                           .where.not(id: current_user.id)
  end

  def load_members
    authorized_scope(Member, type: :relation, scope_options: { namespace: @namespace })
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

# frozen_string_literal: true

# Common Members actions
module MembershipActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { member }, only: %i[destroy update]
    before_action proc { available_users }, only: %i[new create]
    before_action proc { access_levels }, only: %i[new create index update]
    before_action proc { context_crumbs }, only: %i[index new]
  end

  def index
    authorize! @namespace, to: :member_listing?
    @members = authorized_scope(Member, type: :relation, scope_options: { namespace: @namespace })
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

  def destroy
    Members::DestroyService.new(@member, @namespace, current_user).execute
    if @member.destroyed?
      flash[:success] = t('.success')
    else
      flash[:error] = @member.errors.full_messages.first
    end
    redirect_to members_path
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

  private

  def access_levels # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    if @namespace.parent&.user_namespace? && @namespace.parent.owner == current_user
      @access_levels = Member::AccessLevel.access_level_options_owner
    else
      if @namespace.group_namespace?
        member = Member.where(user: current_user,
                              namespace: @namespace.self_and_ancestors).order(:access_level).last
      else
        member = Member.where(user: current_user,
                              namespace: @namespace.self_and_ancestors)
                       .or(Member.where(user: current_user,
                                        namespace: @namespace.parent&.self_and_ancestors)).order(:access_level).last

      end
      @access_levels = Member.access_levels(member) unless member.nil?
    end
  end

  def available_users
    namespaces_to_search = if @namespace.group_namespace?
                             @namespace.self_and_ancestor_ids
                           else
                             @namespace.self_and_ancestor_ids + @namespace.parent&.self_and_ancestor_ids
                           end
    # Remove current user from available users as a user cannot add themselves
    @available_users = User.where.not(id: Member.where(
      namespace: namespaces_to_search
    ).pluck(:user_id)).to_a - [current_user]
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

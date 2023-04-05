# frozen_string_literal: true

# Common Members actions
module MembershipActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { member }, only: %i[destroy]
    before_action proc { available_users }, only: %i[new create]
    before_action proc { access_levels }, only: %i[new create]
    before_action proc { context_crumbs }, only: %i[index new]
  end

  def index
    @members = Member.where(namespace_id: @namespace.id)
  end

  def new
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
      flash[:error] = @new_member.errors.full_messages.first
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

  private

  def access_levels
    member = Member.find_by(user: current_user, namespace: @namespace, type: @member_type)
    @access_levels = Member.access_levels(member)
  end

  def available_users
    # Remove current user from available users as a user cannot add themselves
    @available_users = User.where.not(id: Member.where(
      type: @member_type,
      namespace_id: @namespace.id
    ).pluck(:user_id)).to_a - [current_user]
  end

  protected

  def members_path
    raise NotImplementedError
  end

  def member_namespace
    raise NotImplementedError
  end
end

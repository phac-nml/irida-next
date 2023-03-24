# frozen_string_literal: true

# Common Members actions
module MembershipActions
  extend ActiveSupport::Concern

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
    respond_to do |format|
      @new_member = Member.new(member_params.merge(created_by_id: current_user.id, type: @member_type,
                                                   namespace_id: @namespace.id))
      if @new_member.save
        flash[:success] = t('.success')
        format.html { redirect_to members_path }
      else
        flash[:error] = t('.error')
        format.html do
          render :new, status: :unprocessable_entity, locals: {
            member: @new_member
          }
        end
      end
    end
  end

  def destroy
    if @member.nil?
      flash[:error] = t('.success')
      render status: :unprocessable_entity, json: {
        message: t('.error')
      }
    else
      @member.destroy
      flash[:success] = t('.success')
      redirect_to members_path
    end
  end

  private

  def access_levels
    member_user = Member.find_by(user: current_user, namespace: @namespace, type: @member_type)
    @access_levels = Member.access_levels(member_user, current_user.id == @namespace.owner_id)
  end

  def available_users
    @available_users = User.where.not(id: Member.where(type: @member_type,
                                                       namespace_id: @namespace.id).pluck(:user_id))
    # Remove current user from available users as a user cannot add themselves
    @available_users = @available_users.to_a - [current_user]
  end

  protected

  def members_path
    raise NotImplementedError
  end
end

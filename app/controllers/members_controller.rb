# frozen_string_literal: true

# Controller actions for Members
class MembersController < ApplicationController
  before_action :member, only: %i[destroy]
  before_action :namespace, only: %i[index new create]
  before_action :access_levels, only: %i[new create]

  layout :resolve_layout

  def index
    @members = Member.where(namespace_id: @namespace.id)
  end

  def new
    @available_users = User.where.not(id: Member.where(type: @member_type, namespace_id: @namespace.id).pluck(:user_id))
    @new_member = Member.new(namespace_id: @namespace.id)

    respond_to do |format|
      format.html do
        render 'members/new'
      end
    end
  end

  def create
    respond_to do |format|
      @new_member = Member.new(member_params.merge(created_by_id: current_user.id, type: @member_type,
                                                   namespace_id: @namespace.id))
      if @new_member.save
        flash[:success] = t('.success')
        format.html { redirect_to members_list_path }
      else
        flash[:error] = t('.error')
        format.html { render :new, status: :unprocessable_entity, locals: { member: @new_member } }
      end
    end
  end

  def destroy
    @member.destroy
    redirect_to members_list_path(namespace_id: member_params[:namespace_id])
  end

  def member_params
    params.require(:member).permit(:user_id, :access_level, :type, :namespace_id)
  end

  private

  def member
    @member ||= Member.find_by(id: request.params[:member_id])
  end

  def namespace
    @namespace ||= Namespace.find_by(path: request.params[:format] ||
                    request.params[:id] ||
                    request.params[:namespace_id])
    @member_type = @namespace.type == 'Group' ? 'GroupMember' : 'ProjectMember'
    @group = @namespace if @namespace.type == 'Group'
  end

  def access_levels
    @access_levels = Member::AccessLevel.access_level_options
  end

  def resolve_layout
    case action_name
    when 'new', 'create', 'index'
      if @namespace && @namespace.type == 'Group'
        'groups'
      else
        'application'
      end
    else
      'application'
    end
  end
end

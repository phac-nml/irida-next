# frozen_string_literal: true

# Controller actions for Groups
class MembersController < ApplicationController
  before_action :member, only: %i[destroy]

  def index # rubocop:disable Metrics/AbcSize
    @n = Namespace.where(id: request.params[:namespace_id] || request.params[:id])
    @page_name = "#{@n.first.type} #{@n.first.name} Members"
    @members = Member.where(namespace_id: request.params[:namespace_id] || request.params[:id])
  end

  def show
    @member_name = 'Fred Penner'
    respond_to do |format|
      format.html do
        render 'members/show'
      end
    end
  end

  def new
    @members = Member.where.not(namespace_id: request.params[:namespace_id])
    @namespace_type = request.params[:type] == 'Group' ? 'Group' : 'Project'
    @new_member = Member.new(namespace_id: request.params[:namespace_id])
    @roles = [{ key: 'Owner', value: 'GROUP_OWNER' }, { key: 'Collaborator', value: 'GROUP_USER' }]
    respond_to do |format|
      format.html do
        render 'members/new'
      end
    end
  end

  def create # rubocop:disable Metrics/AbcSize
    respond_to do |format|
      @new_member= Member.new(member_params.merge(created_by: current_user))
      if @new_member.save
        flash[:success] = I18n.t('member.add_success')
        format.html { redirect_to members_path(namespace_id: member_params[:namespace_id]) }
      else
        flash[:error] = "Nope"
        format.html { render :new, status: :unprocessable_entity, locals: { member: @new_member } }
      end
    end
  end

  def destroy
    @member.destroy
    redirect_to members_path(namespace_id: member_params[:namespace_id])
  end

  def member_params
    params.require(:member).permit(:user_id, :namespace_id, :role)
  end

  def member
    @member ||= Member.find_by(id: request.params[:id])
  end
end

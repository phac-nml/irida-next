# frozen_string_literal: true

# Controller actions for Groups
class MembersController < ApplicationController
  def index
    @page_name = 'Members'
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
    @members = Member.all
    respond_to do |format|
      format.html do
        render 'members/new'
      end
    end
  end

  def create
    respond_to do |format|
      @member = Member.new(member_params)
      if @member.save
        flash[:success] = I18n.t('member.add_success')
        format.html { redirect_to members_path }
      else
        format.html { render :new, status: :unprocessable_entity, locals: { member: @member } }
      end
    end
  end

  def member_params
    params.require(:member).permit(:user_id, :namespace_id, :role)
  end
end

# frozen_string_literal: true

# Common share actions
module ShareActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
  end

  def share # rubocop:disable Metrics/AbcSize
    namespace_group_link = Namespaces::GroupShareService.new(current_user, params[:shared_group_id], @namespace,
                                                             params[:group_access_level]).execute
    if namespace_group_link
      if namespace_group_link.errors.full_messages.count.positive?
        flash[:error] = namespace_group_link.errors.full_messages.first
        render :edit, status: :conflict
      else
        flash[:success] = t('.success')
        redirect_to namespace_path
      end
    else
      flash[:error] = t('.error')
      render :edit, status: :unprocessable_entity
    end
  end

  def unshare
    ngl = Namespaces::GroupUnshareService.new(current_user, params[:shared_group_id], @namespace).execute

    if ngl.deleted?
      flash[:success] = "Successfully unshared #{@namespace.type} with group"
    else
      flash[:error] = "Successfully unsharing #{@namespace.type} with group"
    end
  end

  protected

  def namespace_path
    raise NotImplementedError
  end
end

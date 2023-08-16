# frozen_string_literal: true

# Common share actions
module ShareActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    # before_action proc { access_levels }
    before_action proc { namespace_group_link }, only: %i[share_update]
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
    if Namespaces::GroupUnshareService.new(current_user, params[:shared_group_id],
                                           @namespace).execute
      flash[:success] = t('.success')
      redirect_to namespace_path
    else
      flash[:error] =
        @namespace.errors.full_messages.first
      render :edit, status: :unprocessable_entity
    end
  end

  def share_update
    updated = Namespaces::GroupShareUpdateService.new(current_user, @namespace_group_link, params)

    if updated
      flash[:success] = t('success')
      redirect_to namespace_path
    else
      flash[:error] = t('error')
    end
    #
    # respond_to do |format|
    #   if updated
    #     format.turbo_stream do
    #       render status: :ok, locals: { namespace_group_link: @namespace_group_link,
    #                                     access_levels: @access_levels
    #                                     type: 'success',
    #                                     message: t('.success') }
    #     end
    #   else
    #     format.turbo_stream do
    #       render status: :bad_request,
    #              locals: { namespace_group_link: @namespace_group_link, type: 'alert',
    #                        message: t('.error') }
    #     end
    #   end
    # end
  end

  protected

  def namespace_path
    raise NotImplementedError
  end

  private

  def namespace_group_link
    @namespace_group_link ||= NamespaceGroupLink.find_by(id: params[:namespace_group_link_id])
  end
end

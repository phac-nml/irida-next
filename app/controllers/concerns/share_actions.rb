# frozen_string_literal: true

# Common share actions
module ShareActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { access_levels }, only: %i[index create update new]
    before_action proc { namespace_group_link }, only: %i[destroy update]
  end

  def index
    respond_to do |format|
      format.html do
        @has_namespace_group_links = true
      end
      format.turbo_stream do
        @pagy, @namespace_group_links = pagy(authorized_scope(NamespaceGroupLink, type: :relation, scope_options: { namespace: @namespace })) # rubocop:disable Layout/LineLength
      end
    end
  end

  def new
    @new_group_link = NamespaceGroupLink.new(namespace_id: @namespace.id)
  end

  def create # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    @namespace_group_link = GroupLinks::GroupLinkService.new(current_user, @namespace, group_link_params).execute
    respond_to do |format| # rubocop:disable Metrics/BlockLength
      if @namespace_group_link
        if @namespace_group_link.errors.full_messages.count.positive?
          format.turbo_stream do
            render status: :conflict,
                   locals: { namespace_group_link: @namespace_group_link, type: 'alert',
                             message: @namespace_group_link.errors.full_messages.first }
          end
        else
          @group_invited = true
          # namespace group link in which the group is previously linked to an ancestor of the namespace
          @existing_namespace_group_link = @namespace.shared_with_group_links.of_ancestors
                                                     .where(group_id: group_link_params[:group_id])
                                                     .order(:group_access_level).last

          format.turbo_stream do
            render status: :ok, locals: { namespace_group_link: @namespace_group_link,
                                          access_levels: @access_levels,
                                          type: 'success',
                                          message: t('.success', namespace_name: @namespace.name,
                                                                 group_name: @namespace_group_link.group.name) }
          end
        end
      else
        format.turbo_stream do
          render status: :bad_request,
                 locals: { type: 'alert',
                           message: t('.error') }
        end
      end
    end
  end

  def destroy # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    GroupLinks::GroupUnlinkService.new(current_user, @namespace_group_link).execute
    respond_to do |format|
      if @namespace_group_link
        if @namespace_group_link.deleted?
          # namespace group link in which the group is linked to an ancestor of the namespace
          @existing_namespace_group_link = @namespace.shared_with_group_links.of_ancestors
                                                     .where(group_id: @namespace_group_link.group_id)
                                                     .order(:group_access_level).last

          format.turbo_stream do
            render status: :ok, locals: { namespace_group_link: @namespace_group_link, type: 'success',
                                          message: t('.success', namespace_name: @namespace.name,
                                                                 group_name: @namespace_group_link.group.name) }
          end
        else
          format.turbo_stream do
            render status: :unprocessable_entity,
                   locals: { namespace_group_link: @namespace_group_link, type: 'alert',
                             message: @namespace_group_link.errors.full_messages.first }
          end
        end
      else
        format.turbo_stream do
          render status: :bad_request,
                 locals: { type: 'alert',
                           message: t('error') }
        end
      end
    end
  end

  def update # rubocop:disable Metrics/MethodLength
    updated = GroupLinks::GroupLinkUpdateService.new(current_user, @namespace_group_link, group_link_params).execute
    updated_param = group_link_params[:group_access_level].nil? ? 'expiration date' : 'group access level'
    respond_to do |format|
      if updated
        format.turbo_stream do
          render status: :ok, locals: { namespace_group_link: @namespace_group_link,
                                        access_levels: @access_levels,
                                        type: 'success',
                                        message: t('.success', namespace_name: @namespace.name,
                                                               group_name: @namespace_group_link.group.name,
                                                               param_name: updated_param) }
        end
      else
        format.turbo_stream do
          render status: :unprocessable_entity,
                 locals: { namespace_group_link: @namespace_group_link, type: 'alert',
                           message: t('.error') }
        end
      end
    end
  end

  protected

  def group_links_path
    raise NotImplementedError
  end

  def group_link_namespace
    raise NotImplementedError
  end

  private

  def access_levels
    @access_levels = Member::AccessLevel.access_level_options_for_user(@namespace, current_user)
  end
end

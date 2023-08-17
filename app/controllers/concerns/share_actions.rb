# frozen_string_literal: true

# Common share actions
module ShareActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { access_levels }, only: %i[index update]
    before_action proc { namespace_group_link }, only: %i[destroy update]
  end

  def index
    @namespace_group_links = NamespaceGroupLink.find_by(id: @namespace.id)
  end

  def create # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    namespace_group_link = Namespaces::GroupLinkService.new(current_user, @namespace, group_link_params).execute
    respond_to do |format|
      if namespace_group_link
        if namespace_group_link.errors.full_messages.count.positive?
          format.turbo_stream do
            render status: :conflict,
                   locals: { namespace_group_link: @namespace_group_link, type: 'alert',
                             message: namespace_group_link.errors.full_messages.first }
          end
        else
          format.turbo_stream do
            render status: :ok, locals: { namespace_group_link: @namespace_group_link,
                                          access_levels: @access_levels,
                                          type: 'success',
                                          message: t('.success') }
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

  def destroy # rubocop:disable Metrics/MethodLength
    Namespaces::GroupUnlinkService.new(current_user, @namespace_group_link).execute
    respond_to do |format|
      if @namespace_group_link
        if @namespace_group_link.deleted?
          format.turbo_stream do
            render status: :ok, locals: { namespace_group_link: @namespace_group_link, type: 'success',
                                          message: t('.success') }
          end
        else
          format.turbo_stream do
            render status: :unprocessable_entity,
                   locals: { namespace_group_link: @namespace_group_link, type: 'alert',
                             message: @member.errors.full_messages.first }
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
    updated = Namespaces::GroupLinkUpdateService.new(current_user, @namespace_group_link, group_link_params).execute
    respond_to do |format|
      if updated
        format.turbo_stream do
          render status: :ok, locals: { namespace_group_link: @namespace_group_link,
                                        access_levels: @access_levels,
                                        type: 'success',
                                        message: t('.success') }
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
end

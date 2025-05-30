# frozen_string_literal: true

module Groups
  # Controller actions for Group Attachments
  class AttachmentsController < Groups::ApplicationController
    include Metadata
    include AttachmentActions

    before_action :group
    before_action :page_title

    private

    def view_authorizations
      @allowed_to = {
        create_attachment: allowed_to?(:create_attachment?, @group),
        destroy_attachment: allowed_to?(:destroy_attachment?, @group)
      }
    end

    def group
      @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
    end

    def set_namespace
      @namespace = group
    end

    def set_authorization_object
      @authorize_object = group
    end

    def current_page
      @current_page = t(:'groups.sidebar.files')
    end

    def context_crumbs
      super
      @context_crumbs +=
        [{
          name: t(:'groups.sidebar.files'),
          path: group_attachments_path(@group)
        }]
    end

    def page_title
      @title = "#{t(:'groups.sidebar.files')} · #{t(:'shared.group_name', name: @group.name)}"
    end
  end
end

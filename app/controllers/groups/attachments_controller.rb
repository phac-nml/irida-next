# frozen_string_literal: true

module Groups
  # Controller actions for Group Attachments
  class AttachmentsController < Groups::ApplicationController
    include Metadata
    include AttachmentActions

    before_action :group

    private

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
          path: group_attachments_path(@namespace)
        }]
    end
  end
end

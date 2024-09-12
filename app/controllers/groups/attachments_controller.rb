# frozen_string_literal: true

module Groups
  # Controller actions for Group Attachments
  class AttachmentsController < Groups::ApplicationController
    def index; end
    def new; end

    def create
      authorize! @group, to: :create_attachment?
    end

    def destroy
      authorize! @group, to: :destroy_attachment?
    end
  end
end

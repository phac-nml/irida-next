# frozen_string_literal: true

module Groups
  # Base Controller for Groups
  class ApplicationController < ApplicationController
    layout 'groups'

    def authorize_owner_group!
      authorize! @group
    end

    def authorize_create_group!
      authorize! @group unless @group&.parent.nil?
    end

    def authorize_viewable_group_member!
      authorize! @group
    end

    def authorize_owner_namespace!
      authorize! @group
    end

    def authorize_view_members!
      authorize! @namespace, to: :allowed_to_view_members?
    end
  end
end

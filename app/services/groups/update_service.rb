# frozen_string_literal: true

module Groups
  # Service used to Update Groups
  class UpdateService < BaseGroupService
    attr_accessor :group

    def initialize(group, user = nil, params = {})
      super
    end

    def execute # rubocop:disable Metrics/AbcSize
      authorize! @group, to: :update?
      updated = group.update(params)

      if updated
        if group.parent.nil?
          if params[:public].present? && params[:public] == true
            update_descendants_to_public
          elsif params[:public].present? && params[:public] == false
            update_descendants_to_private
          end
        end

        @group.create_activity key: 'group.update',
                               owner: current_user
      end

      updated
    end
  end
end

# frozen_string_literal: true

module Groups
  # Service used to Update Groups
  class UpdateService < BaseGroupService
    attr_accessor :group

    def initialize(group, user = nil, params = {})
      super
    end

    def execute # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      authorize! @group, to: :update? unless params.key?(:public)
      authorize! @group, to: :change_visibility? if (params.to_unsafe_h.size == 1) && params.key?(:public)

      updated = group.update(params)

      if updated
        if group.parent.nil?
          if params.key?(:public) && params[:public] == 'true'
            update_descendants_to_public
          elsif params.key?(:public) && params[:public] == 'false'
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

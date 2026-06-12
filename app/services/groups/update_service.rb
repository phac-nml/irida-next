# frozen_string_literal: true

module Groups
  # Service used to Update Groups
  class UpdateService < BaseGroupService
    attr_accessor :group

    def initialize(group, user = nil, params = {})
      super
    end

    def execute # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
      authorize! @group, to: :update? unless params.key?(:public)
      authorize! @group, to: :change_visibility? if params.key?(:public)

      updated = group.update(params)

      if updated
        if group.parent.nil? && params.key?(:public)
          public_param_normalized = params[:public].to_s

          if public_param_normalized == 'true'
            update_descendants_to_public
          elsif public_param_normalized == 'false'
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

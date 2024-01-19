# frozen_string_literal: true

module Groups
  # Service used to Delete Groups
  class DestroyService < BaseService
    attr_accessor :group

    def initialize(group, user = nil, params = {})
      super(user, params.except(:group, :group_id))
      @group = group
    end

    def execute
      authorize! @group, to: :destroy?
      group.destroy

      return unless group.deleted? && !group.parent.nil?

      group.update_metadata_summary_by_namespace_deletion
    end
  end
end

# frozen_string_literal: true

module GroupListTree
  class GroupRowComponent < ViewComponent::Base
      with_collection_parameter :group

      def initialize(group:)
        @group = group
      end

  end
end

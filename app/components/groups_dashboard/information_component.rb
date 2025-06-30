# frozen_string_literal: true

module GroupsDashboard
  # Component for rendering a group information
  class InformationComponent < Component
    attr_accessor :group

    def initialize(group:)
      @group = group
    end

    def render?
      group.present?
    end

    def group_description
      group.description.presence || t('components.groups_dashboard.information_component.no_description')
    end
  end
end

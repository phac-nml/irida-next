# frozen_string_literal: true

module Groups
  # Controller actions for Samples within a Group
  class SamplesController < ApplicationController
    layout 'groups'
    before_action :context_crumbs, only: %i[index]

    def index
      @samples = Sample.where(project_id: Project.where(namespace_id: group.descendant_ids)).includes(:project)
    end

    private

    def group
      return unless params[:group_id]

      @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
    end

    def context_crumbs
      case action_name
      when 'index'
        @context_crumbs = [{
          name: I18n.t('groups.samples.index.title'),
          path: group_samples_path
        }]
      end
    end
  end
end

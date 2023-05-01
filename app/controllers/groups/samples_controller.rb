# frozen_string_literal: true

module Groups
  # Controller actions for Samples within a Group
  class SamplesController < ApplicationController
    layout 'groups'
    before_action :context_crumbs, only: %i[index]

    def index
      @pagy, @samples = pagy(Sample.where(project_id: Project.where(namespace_id: group.descendant_ids)).includes(:project))

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    private

    def group
      @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
    end

    def context_crumbs
      @context_crumbs = [{
        name: I18n.t('groups.samples.index.title'),
        path: group_samples_path
      }]
    end
  end
end

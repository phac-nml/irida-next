# frozen_string_literal: true

module Groups
  # Controller actions for Samples within a Group
  class SamplesController < ApplicationController
    layout 'groups'
    before_action :context_crumbs, only: %i[index]

    def index
      respond_to do |format|
        format.html do
          @has_samples = Sample.joins(project: [:namespace]).exists?(namespace: { parent_id: group.self_and_descendant_ids }) # rubocop:disable Layout/LineLength
        end
        format.turbo_stream do
          @pagy, @samples = pagy(Sample.joins(project: [:namespace]).where(namespace: { parent_id: group.self_and_descendant_ids }).includes(:project)) # rubocop:disable Layout/LineLength
        end
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

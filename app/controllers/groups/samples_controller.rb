# frozen_string_literal: true

module Groups
  # Controller actions for Samples within a Group
  class SamplesController < ApplicationController
    layout 'groups'
    before_action :group, :current_page, only: %i[index]

    def index
      authorize! @group, to: :sample_listing?
      samples = authorized_samples
      respond_to do |format|
        format.html do
          @has_samples = samples.length.positive?
        end
        format.turbo_stream do
          @pagy, @samples = pagy(samples)
        end
      end
    end

    private

    def group
      @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
    end

    def authorized_samples
      authorized_scope(Sample, type: :relation, scope_options: { group: @group })
    end

    def context_crumbs
      super
      case action_name
      when 'index'
        @context_crumbs += [{
          name: I18n.t('groups.samples.index.title'),
          path: group_samples_path
        }]
      end
    end

    def current_page
      @current_page = 'samples'
    end
  end
end

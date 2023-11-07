# frozen_string_literal: true

module Projects
  module Samples
    # Base Controller Samples
    class ApplicationController < Projects::ApplicationController
      before_action :sample

      private

      def sample
        @sample = @project.samples.find_by(id: params[:sample_id]) || not_found
      end
    end
  end
end

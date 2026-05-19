# frozen_string_literal: true

module Projects
  module Samples
    # Base Controller Samples
    class ApplicationController < Projects::ApplicationController
      before_action :sample

      private

      def sample
        @sample = @project.samples.find(params.expect(:sample_id))
      end
    end
  end
end

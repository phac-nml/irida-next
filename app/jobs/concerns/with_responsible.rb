# frozen_string_literal: true

# concern to wrap perform with logidze with_responsible
module WithResponsible
  extend ActiveSupport::Concern

  included do
    around_perform do |job, block|
      Logidze.with_responsible(job.arguments.second&.id, transactional: false) do
        block.call
      end
    end
  end
end

# frozen_string_literal: true

# entity class for Jobs
class JobsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: :jobs
end

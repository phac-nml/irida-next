# frozen_string_literal: true

GoodJob.configure_active_record do
  connects_to database: :jobs
  self.table_name_prefix = 'jobs_'
end

GoodJob.active_record_parent_class = 'JobsRecord'

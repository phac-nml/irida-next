# frozen_string_literal: true

# Run rake tasks with any of the following to have output printed to console
# example: rake debug db:seed
desc 'switch rails logger to stdout'
task verbose: [:environment] do
  Rails.logger = Logger.new($stdout)
end

desc 'switch rails logger log level to debug'
task debug: %i[environment verbose] do
  Rails.logger.level = Logger::DEBUG
end

desc 'switch rails logger log level to info'
task info: %i[environment verbose] do
  Rails.logger.level = Logger::INFO
end

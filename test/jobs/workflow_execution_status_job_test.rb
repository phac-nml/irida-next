# frozen_string_literal: true

require 'minitest/mock'
require 'test_helper'

class WorkflowExecutionStatusJobTest < ActiveJob::TestCase
  def setup
    @workflow_execution = workflow_executions(:irida_next_example_submitted)
  end

  test 'retry on no connection' do
    mock = Minitest::Mock.new
    def mock.conn
      Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.get('/runs/my_run_id_5/status') do |_env|
            [
              401,
              { 'Content-Type': 'text/plain' },
              'aaaaaaaaaaaaaaaaa'
            ]
          end

          stub.get('/boom') do
            raise Faraday::ConnectionFailed
          end
        end
      end
    end

    # stubs.get('/asdf') { |_env| [200, {}, 'qwerty'] }

    Integrations::Ga4ghWesApi::V1::ApiConnection.stub :new, mock do
      perform_enqueued_jobs do
        WorkflowExecutionStatusJob.set(wait_until: 30.seconds.from_now).perform_later(@workflow_execution)
      end
    end
  end
end

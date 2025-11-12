# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionActionsSearchParamsTest < ActiveSupport::TestCase
  class FakeController
    def self.before_action(*) = nil

    include WorkflowExecutionActions

    def initialize
      @params = ActionController::Parameters.new
      @session = {}
      @namespace = nil
    end

    attr_accessor :params
    attr_reader :session

    private

    def update_store(_search_key, value)
      @session.merge!(value)
      @session
    end

    def get_store(_search_key)
      @session
    end

    def search_key
      'workflow_executions'
    end
  end

  test 'search_params converts ransack sort parameter into sort key' do
    controller = FakeController.new
    controller.params = ActionController::Parameters.new(q: { s: 'name asc' })

    search_params = controller.send(:search_params)

    assert_equal 'name asc', search_params[:sort]
    assert_nil search_params[:s]
  end

  test 'search_params preserves active filters when converting sort parameter' do
    controller = FakeController.new
    params = ActionController::Parameters.new(
      q: {
        s: 'updated_at desc',
        name_or_id_cont: 'example'
      }
    )
    controller.params = params

    search_params = controller.send(:search_params)

    assert_equal 'updated_at desc', search_params[:sort]
    assert_equal 'example', search_params[:name_or_id_cont]
    assert_nil search_params[:s]
  end
end

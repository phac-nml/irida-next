# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

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

  test 'workflow_name_enum_fields handles both string and hash names' do
    pipeline_struct = Struct.new(:name)
    pipelines = {
      'p1' => pipeline_struct.new('String Name'),
      'p2' => pipeline_struct.new({ 'en' => 'Translated Name' })
    }

    mock_pipelines = Minitest::Mock.new
    mock_pipelines.expect :pipelines, pipelines, ['executable']

    original_instance = Irida::Pipelines.instance
    Irida::Pipelines.instance = mock_pipelines

    begin
      controller = FakeController.new
      enum_fields = controller.send(:workflow_name_enum_fields)

      assert_includes enum_fields[:values], 'String Name'
      assert_includes enum_fields[:values], 'Translated Name'
    ensure
      Irida::Pipelines.instance = original_instance
    end
  end

  test 'workflow_name_enum_fields ensures unique values when duplicate names exist' do
    pipeline_struct = Struct.new(:name)
    pipelines = {
      'p1' => pipeline_struct.new('Assembly'),
      'p2' => pipeline_struct.new({ 'en' => 'Assembly', 'fr' => 'Assemblage' }),
      'p3' => pipeline_struct.new('Annotation')
    }

    mock_pipelines = Minitest::Mock.new
    mock_pipelines.expect :pipelines, pipelines, ['executable']

    original_instance = Irida::Pipelines.instance
    Irida::Pipelines.instance = mock_pipelines

    begin
      controller = FakeController.new
      enum_fields = controller.send(:workflow_name_enum_fields)

      # Should only have 2 unique values, not 3
      assert_equal 2, enum_fields[:values].length
      assert_includes enum_fields[:values], 'Assembly'
      assert_includes enum_fields[:values], 'Annotation'
      assert_equal({ 'Assembly' => 'Assembly', 'Annotation' => 'Annotation' }, enum_fields[:labels])
    ensure
      Irida::Pipelines.instance = original_instance
    end
  end
end

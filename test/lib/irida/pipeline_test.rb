# frozen_string_literal: true

require 'test_helper'

class PipelinesTest < ActiveSupport::TestCase
  test 'automatable' do
    pipeline = Irida::Pipeline.new('test/pipeline',
                                   { 'name' => 'Test Pipeline', 'description' => 'A test pipeline',
                                     'url' => 'http://example.com' },
                                   { 'name' => '1.0.0', 'automatable' => true, 'executable' => true },
                                   nil,
                                   nil)
    assert pipeline.automatable?
  end

  test 'not automatable' do
    pipeline = Irida::Pipeline.new('test/pipeline',
                                   { 'name' => 'Test Pipeline', 'description' => 'A test pipeline',
                                     'url' => 'http://example.com' },
                                   { 'name' => '1.0.0', 'automatable' => false, 'executable' => true },
                                   nil,
                                   nil)
    assert_not pipeline.automatable?
  end

  test 'executable' do
    pipeline = Irida::Pipeline.new('test/pipeline',
                                   { 'name' => 'Test Pipeline', 'description' => 'A test pipeline',
                                     'url' => 'http://example.com' },
                                   { 'name' => '1.0.0', 'automatable' => true, 'executable' => true },
                                   nil,
                                   nil)
    assert pipeline.executable?
  end

  test 'not executable' do
    pipeline = Irida::Pipeline.new('test/pipeline',
                                   { 'name' => 'Test Pipeline', 'description' => 'A test pipeline',
                                     'url' => 'http://example.com' },
                                   { 'name' => '1.0.0', 'automatable' => false, 'executable' => false },
                                   nil,
                                   nil)
    assert_not pipeline.executable?
  end

  test 'unknown pipeline' do
    pipeline = Irida::Pipeline.new('test/pipeline',
                                   { 'name' => 'Test Pipeline', 'description' => 'A test pipeline',
                                     'url' => 'http://example.com' },
                                   { 'name' => '1.0.0' },
                                   nil,
                                   nil,
                                   unknown: true)
    assert pipeline.unknown?
  end

  test 'disabled pipeline' do
    pipeline1 = Irida::Pipeline.new('test/pipeline1',
                                    { 'name' => 'Test Pipeline 1', 'description' => 'A test pipeline',
                                      'url' => 'http://example.com' },
                                    { 'name' => '1.0.0' },
                                    nil,
                                    nil,
                                    unknown: true)
    pipeline2 = Irida::Pipeline.new('test/pipeline2',
                                    { 'name' => 'Test Pipeline 2', 'description' => 'A test pipeline',
                                      'url' => 'http://example.com' },
                                    { 'name' => '1.0.0', 'automatable' => true, 'executable' => false },
                                    nil,
                                    nil)
    pipeline3 = Irida::Pipeline.new('test/pipeline3',
                                    { 'name' => 'Test Pipeline 3', 'description' => 'A test pipeline',
                                      'url' => 'http://example.com' },
                                    { 'name' => '1.0.0', 'automatable' => false, 'executable' => true },
                                    nil,
                                    nil)
    assert pipeline1.disabled?
    assert pipeline2.disabled?
    assert pipeline3.disabled?
  end
end

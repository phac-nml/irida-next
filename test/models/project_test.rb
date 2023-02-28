# frozen_string_literal: true

require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  def setup
    @project = projects(:project1)
  end

  test 'valid project' do
    assert @project.valid?
  end
end

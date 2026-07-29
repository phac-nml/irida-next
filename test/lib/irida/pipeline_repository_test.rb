# frozen_string_literal: true

require 'test_helper'
require 'mocha/minitest'
require 'irida/pipeline_repository'
require 'securerandom'
require 'tmpdir'

class PipelineRepositoryTest < ActiveSupport::TestCase
  setup do
    @pipeline_repository = Irida::PipelineRepository.allocate
  end

  test 'git_repo? validates repo with fsck full option' do
    path = '/tmp/repo.git'
    git_repo = mock('git_repo')

    Git.expects(:bare).with(path).returns(git_repo)
    git_repo.expects(:fsck).with(full: true).once
    FileUtils.expects(:rm_rf).never

    assert @pipeline_repository.send(:git_repo?, path)
  end

  test 'git_repo? cleans up invalid repo when git raises error' do
    path = '/tmp/repo.git'

    Git.expects(:bare).with(path).raises(Git::Error.new('invalid repo'))
    FileUtils.expects(:rm_rf).with(path).once

    assert_not @pipeline_repository.send(:git_repo?, path)
  end

  test 'git_repo? cleans up invalid repo when fsck raises argument error' do
    path = '/tmp/repo.git'
    git_repo = mock('git_repo')

    Git.expects(:bare).with(path).returns(git_repo)
    git_repo.expects(:fsck).with(full: true).raises(ArgumentError)
    FileUtils.expects(:rm_rf).with(path).once

    assert_not @pipeline_repository.send(:git_repo?, path)
  end

  test 'git_repo? returns false for a real non-git directory' do
    path = File.join(Dir.tmpdir, "invalid-git-repo-#{SecureRandom.hex(8)}")
    Dir.mkdir(path)
    File.write(File.join(path, 'README.txt'), 'not a git repository')

    assert_not @pipeline_repository.send(:git_repo?, path)
    assert_not Dir.exist?(path)
  ensure
    FileUtils.rm_rf(path) if path && Dir.exist?(path)
  end
end

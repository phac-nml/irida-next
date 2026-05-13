# frozen_string_literal: true

require 'git'

module Irida
  # Handles Git repository operations for pipeline cloning and verification
  class PipelineRepository
    attr_reader :repo, :repo_dir

    def self.mirror_repo(uri, repo_dir)
      new(uri, repo_dir)
    end

    def initialize(uri, repo_dir)
      @repo_dir = repo_dir.to_s
      @repo = if git_repo?(repo_dir)
                Git.bare(repo_dir)
              else
                Git.clone(uri.to_s, repo_dir, mirror: true)
              end
      @repo.fetch(prune: true)
    end

    def file_contents_at(sha, path)
      object = @repo.object("#{sha}:#{path}")
      return unless object

      if object.respond_to?(:contents)
        object.contents
      elsif object.respond_to?(:content)
        object.content
      else
        object.to_s
      end
    end

    private

    def git_repo?(path)
      g = Git.bare(path)
      g.lib.fsck('--full')
      true
    rescue ArgumentError, Git::GitExecuteError
      FileUtils.rm_rf(path)
      false
    end
  end
end

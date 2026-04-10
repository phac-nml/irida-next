# frozen_string_literal: true

require 'git'

module Irida
  # Handles Git repository operations for pipeline cloning and verification
  class PipelineRepository
    def self.clone_repo(uri, sha, clone_dir)
      new(uri, sha).clone(clone_dir)
    end

    def initialize(uri, sha)
      @uri = uri
      @sha = sha
      @remote = uri.to_s
    end

    def clone(clone_dir)
      if sha_exists_on_remote?
        Git.clone(@remote, clone_dir, depth: 1, branch: @sha)
      else
        repo = Git.clone(@remote, clone_dir)
        repo.checkout(@sha)
      end
    end

    private

    def sha_exists_on_remote?
      remote_ref_includes?(Git.ls_remote(@remote), @sha)
    end

    def remote_ref_includes?(refs, query)
      case refs
      when Hash
        refs.any? { |key, value| key.to_s == query || remote_ref_includes?(value, query) }
      when Array
        refs.any? { |value| remote_ref_includes?(value, query) }
      else
        refs.to_s == query
      end
    end
  end
end

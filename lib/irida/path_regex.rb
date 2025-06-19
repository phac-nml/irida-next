# frozen_string_literal: true

module Irida
  # Module to encapsulate all path regexs for Irida
  module PathRegex
    module_function

    # All routes that appear on the top level must be listed here.
    # This will make sure that namespaces cannot be created with these names
    # as these routes would be masked by the paths already in place.
    TOP_LEVEL_ROUTES = %w[
      -
      404.html
      422.html
      500.html
      apple-touch-icon-precomposed.png
      apple-touch-icon.png
      activities
      api
      assets
      console
      dashboard
      favicon.ico
      graphiql
      groups
      rails
      recede_historical_location
      resume_historical_location
      refresh_historical_location
      robots.txt
      users
    ].freeze

    # All routes for groups and projects will be under `-` this allows
    # makes namespace validation simpler and more robust. I.E. if we
    # add a new route under the `/-/` scope instead of directly we do
    # not need to worry about existing namespaces that could conflict
    WILDCARD_ROUTES = %w[
      -
    ].freeze

    PATH_BOUND_CHAR = '[a-zA-Z0-9_]'
    PATH_REGEX_STR = format('%<bound_char>s[a-zA-Z0-9_\-\.]+%<bound_char>s', bound_char: PATH_BOUND_CHAR)

    NAMESPACE_FORMAT_REGEX = /(?:#{PATH_REGEX_STR})/

    def root_namespace_route_regex
      @root_namespace_route_regex ||= begin
        illegal_words = Regexp.new(Regexp.union(TOP_LEVEL_ROUTES).source, Regexp::IGNORECASE)

        %r{(?!(#{illegal_words})/)#{NAMESPACE_FORMAT_REGEX}}x
      end
    end

    def full_namespace_route_regex
      @full_namespace_route_regex ||= begin
        illegal_words = Regexp.new(Regexp.union(WILDCARD_ROUTES).source, Regexp::IGNORECASE)

        %r{#{root_namespace_route_regex}(?:/(?!#{illegal_words}/)#{NAMESPACE_FORMAT_REGEX})*}x
      end
    end

    def project_route_regex
      @project_route_regex ||= begin
        illegal_words = Regexp.new(Regexp.union(WILDCARD_ROUTES).source, Regexp::IGNORECASE)

        %r{(?!(#{illegal_words})/)#{NAMESPACE_FORMAT_REGEX}}x
      end
    end

    def full_namespace_path_regex
      @full_namespace_path_regex ||= %r{\A#{full_namespace_route_regex}/\z}
    end

    def namespace_format_regex
      @namespace_format_regex ||= /\A#{NAMESPACE_FORMAT_REGEX}\z/o
    end
  end
end

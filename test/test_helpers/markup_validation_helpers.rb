# frozen_string_literal: true

module MarkupValidationHelpers
  def format_nokogiri_errors(errors)
    results = errors.map(&:to_s).join("\n    ")

    %(
    Found markup violations:
    #{results}
    )
  end

  def assert_valid_markup(markup)
    # Use HTML5 fragment parsing with parse errors enabled.
    # This keeps support for modern tags while still failing malformed markup.
    result = Nokogiri::HTML5.fragment(markup, max_errors: 100)

    assert result.errors.empty?, format_nokogiri_errors(result.errors)
  end
end

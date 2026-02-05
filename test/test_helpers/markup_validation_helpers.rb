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
    # Use HTML5 fragment parsing instead of strict XML
    # HTML5 fragments handle modern tags like <template> and allow trailing whitespace
    result = Nokogiri::HTML5.fragment(markup)

    assert result.errors.empty?, format_nokogiri_errors(result.errors)
  end
end

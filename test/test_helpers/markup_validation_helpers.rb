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
    result = Nokogiri::XML(markup)

    assert result.errors.empty?, format_nokogiri_errors(result.errors)
  end
end

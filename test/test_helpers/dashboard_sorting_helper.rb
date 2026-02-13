# frozen_string_literal: true

# Shared helper methods for dashboard sorting tests
module DashboardSortingHelper
  # Extracts text from the first treegrid row in the dashboard response
  def first_treegrid_row_text
    Nokogiri::HTML(response.body).at_css('#groups_tree .treegrid-row')&.text.to_s.squish
  end

  # Asserts that a specific sort parameter is active (marked with aria-current="page")
  def assert_active_sort(search_key, expected_sort)
    doc = Nokogiri::HTML(response.body)
    links = doc.css('a[aria-current="page"]')

    assert links.any? { |link| sort_param(link['href'], search_key) == expected_sort },
           "Expected active sort #{expected_sort.inspect} for #{search_key}, but none was found"
  end

  # Extracts the sort parameter from a URL's query string
  def sort_param(href, search_key)
    query = URI.parse(href).query.to_s
    Rack::Utils.parse_nested_query(query).dig(search_key, 's')
  rescue URI::InvalidURIError
    nil
  end
end

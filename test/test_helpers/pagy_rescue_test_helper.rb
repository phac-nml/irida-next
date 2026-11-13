# frozen_string_literal: true

# Shared assertions for verifying ApplicationController's generic rescue_from behavior for
# Pagy::RangeError and Pagy::LimitError across the various controllers/actions that call pagy.
module PagyRescueTestHelper
  # Asserts that requesting +path+ with a page far beyond the available results redirects to the
  # first page, preserving the given (or default) limit, and does not set a flash message.
  #
  # +redirect_path+ defaults to +path+, but can be overridden for actions where multiple routes
  # map to the same controller/action (e.g. Groups#show), since url_for inside the rescue_from
  # handler may resolve to a different (canonical) path than the one originally requested.
  def assert_pagy_range_error_redirects_to_first_page(path, params: {}, limit: 20, redirect_path: path, as: nil, # rubocop:disable Metrics/ParameterLists
                                                      method: :get)
    public_send(method, path, params: params.merge(page: 999_999, limit:), as: as)

    assert_redirected_to "#{redirect_path}?limit=#{limit}&page=1"

    follow_redirect!(as: as)

    assert_response :success
    assert_empty flash
  end

  # Asserts that requesting +path+ with an invalid limit (malformed string, or a clean integer
  # that isn't one of the dropdown options) redirects to the first page with the default limit,
  # and does not set a flash message. See +redirect_path+ note above.
  def assert_pagy_limit_error_redirects_to_default_limit(path, invalid_limit, params: {}, default_limit: 20, # rubocop:disable Metrics/ParameterLists
                                                         redirect_path: path, as: nil, method: :get)
    public_send(method, path, params: params.merge(limit: invalid_limit), as: as)

    assert_redirected_to "#{redirect_path}?limit=#{default_limit}&page=1"

    follow_redirect!(as: as)

    assert_response :success
    assert_empty flash
  end
end

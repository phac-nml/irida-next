# frozen_string_literal: true

# Helper functions for anything to do with URLs
module UrlHelper
  def pagy_template_url_for(pagy, template)
    pagy_url = pagy_url_for(pagy, pagy.page)
    uri = URI.parse(pagy_url)
    params = Rack::Utils.parse_query(uri.query)
    params['template'] = template
    uri.query = Rack::Utils.build_query(params)
    uri.to_s.gsub('samples.turbo_stream', 'samples')
  end
end

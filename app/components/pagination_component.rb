# frozen_string_literal: true

class PaginationComponent < ViewComponent::Base
  include Pagy::Frontend
  attr_reader :results

  def initialize(results:)
    @results = results
  end
end

# frozen_string_literal: true

module Pipeline
  class FormComponent < Component
    attr_reader :url

    def initialize(url:)
      @url = url
    end
  end
end

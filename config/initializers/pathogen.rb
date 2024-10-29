# frozen_string_literal: true

Rails.application.config.to_prepare do
  Rails.application.config.define_singleton_method(:pathogen_view_components) do
    @pathogen_view_components ||= Struct.new(:raise_on_invalid_options).new(!Rails.env.production?)
  end
end

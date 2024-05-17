# frozen_string_literal: true

require 'irida/pipelines'

Rails.application.config.to_prepare do
  Irida::Pipelines.instance = Irida::Pipelines.new if Irida::Pipelines.instance.nil?
end

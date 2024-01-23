# frozen_string_literal: true

# Executes basic metadata template logic for controllers
module MetadataTemplates
  extend ActiveSupport::Concern

  def templates
    @templates = [{ id: 0, label: 'None' }, { id: 1, label: 'All' }]
  end

  def template(namespace = nil, template_id = 0)
    @template = template_id.zero? || namespace.nil? ? [] : namespace.metadata_summary.keys
  end
end

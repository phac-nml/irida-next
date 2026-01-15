# frozen_string_literal: true

# metadata service helper to ensure parsed json metadata is flat
module MetadataHelper
  # Accepts a hash and flattens all nested hashes and arrays using dot notation
  # modified/linted code from https://stackoverflow.com/a/40754652
  def flatten(a_el, a_k = nil) # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
    result = {}

    a_el = a_el.as_json

    if a_el.is_a?(Hash)
      a_el.map do |k, v|
        k = "#{a_k}.#{k}" if a_k.present?
        result.merge!([Hash, Array].include?(v.class) ? flatten(v, k) : { k => v })
      end
    end

    if a_el.is_a?(Array)
      a_el.uniq.each_with_index do |o, i|
        i = "#{a_k}.#{i}" if a_k.present?
        result.merge!([Hash, Array].include?(o.class) ? flatten(o, i) : { i => o })
      end
    end

    result
  end

  def format_id(string)
    string.gsub(/\s+/, '-')
  end
end

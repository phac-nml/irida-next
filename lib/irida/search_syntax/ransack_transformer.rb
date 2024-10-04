# frozen_string_literal: true

module Irida
  module SearchSyntax
    # IRIDA Next specific RansackTransformer that supoorts metadata_fields
    class RansackTransformer < ::SearchSyntax::RansackTransformer
      def initialize(text:, params:, metadata_fields:, sort: nil)
        super(text:, params:, sort:)
        @metadata_fields = metadata_fields
      end

      # Note this method is a copy of SearchSyntax::RanstackTronsformer but with additional processing for metadata
      def transform_with_errors(ast) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        errors = []
        result = {}

        if @allowed_params.length.positive? || @metadata_fields.length.positive?
          ast = ast.filter do |node| # rubocop:disable Metrics/BlockLength
            if node[:type] != :param
              true
            elsif node[:name] == @sort
              result[:s] = transform_sort_param(node[:value])
              false
            elsif @allowed_params.include?(node[:name])
              key = name_with_predicate(node)
              if result.key?(key)
                errors.push(::SearchSyntax::DuplicateParamError.new(
                              name: node[:name],
                              start: node[:start],
                              finish: node[:finish]
                            ))
              else
                result[key] = node[:value]
              end
              false
            elsif @metadata_fields.include?(node[:name])
              # all metadata searching uses metadata_jcont ransacker
              key = 'metadata_jcont'
              search_value = {}
              search_value = JSON.parse(result[key]) if result.key?(key)
              # if we already processed a metadata field, ignore subsequent instances of field and push an error
              if search_value.key?(node[:name])
                errors.push(::SearchSyntax::DuplicateParamError.new(
                              name: node[:name],
                              start: node[:start],
                              finish: node[:finish]
                            ))
              # else add it to the search_value hash and then transform back to a JSON string
              else
                search_value[node[:name]] = node[:value]
                result[key] = JSON.generate(search_value)
              end
              false
            else
              errors.push(::SearchSyntax::UnknownParamError.new(
                            name: node[:name],
                            start: node[:start],
                            finish: node[:finish],
                            did_you_mean: @spell_checker.correct(node[:name])
                          ))
              true
            end
          end
        end

        previous = -1
        result[@text] = ast.map do |node|
          separator = previous == node[:start] || previous == -1 ? '' : ' '
          previous = node[:finish]
          separator + node[:raw]
        end.join

        [result, errors]
      end
    end
  end
end

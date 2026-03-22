# frozen_string_literal: true

module AdvancedSearch
  module V2
    # Converts a V2 query tree between its JSON wire format and Ruby value objects.
    class Serializer
      class ParseError < StandardError
      end

      class << self
        def parse(json)
          return nil if json.blank?

          hash = JSON.parse(json)
          parse_root(hash)
        rescue JSON::ParserError => e
          raise ParseError, "Invalid V2 query JSON: #{e.message}"
        end

        def dump(tree)
          return nil if tree.nil?

          JSON.generate(dump_group(tree))
        end

        private

        def parse_root(hash)
          validate_hash!(hash, 'root group node')
          raise ParseError, 'Top-level query node must be a group' if hash['type'].present? && hash['type'] != 'group'

          parse_group(hash, require_nodes: true)
        end

        def parse_group(hash, require_nodes: false)
          validate_hash!(hash, 'group node')

          nodes = nodes_for(hash, require_nodes:).map { |node| parse_node(node) }
          Tree::GroupNode.new(combinator: hash['combinator'] || 'and', nodes:)
        end

        def parse_condition(hash)
          validate_hash!(hash, 'condition node')

          Tree::ConditionNode.new(
            field: hash['field'],
            operator: hash['operator'],
            value: hash['value']
          )
        end

        def nodes_for(hash, require_nodes: false)
          raise ParseError, 'Expected group node to include nodes' if require_nodes && !hash.key?('nodes')

          raw_nodes = hash['nodes']
          raise ParseError, 'Expected nodes to be an array' if !raw_nodes.nil? && !raw_nodes.is_a?(Array)

          raw_nodes || []
        end

        def parse_node(node)
          validate_hash!(node, 'node')

          case node['type']
          when 'condition' then parse_condition(node)
          when 'group' then parse_group(node)
          else raise ParseError, "Unknown node type: #{node['type']}"
          end
        end

        def validate_hash!(value, label)
          raise ParseError, "Expected #{label} to be an object" unless value.is_a?(Hash)
        end

        def dump_group(node)
          {
            'version' => '2',
            'type' => 'group',
            'combinator' => node.combinator,
            'nodes' => node.nodes.map do |n|
              n.type == :group ? dump_group(n).except('version') : dump_condition(n)
            end
          }
        end

        def dump_condition(node)
          { 'type' => 'condition', 'field' => node.field, 'operator' => node.operator, 'value' => node.value }
        end
      end
    end
  end
end

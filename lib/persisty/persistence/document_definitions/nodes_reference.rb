module Persisty
  module Persistence
    module DocumentDefinitions
      class NodesReference
        class InvalidNodeKind < StandardError; end
        class InvalidNodeDefinition < StandardError; end

        def initialize
          @nodes = { child_node: {}, child_nodes: {}, parent_node: {} }
        end

        def register(kind, node_definition)
          validate_node_definition(node_definition)
          nodes.fetch(kind).merge!(node_definition)
        rescue KeyError
          raise InvalidNodeKind, 'invalid node kind'
        end

        [:parent_node, :child_node].each do |node_type|
          define_method("#{node_type}s_list") do
            nodes[node_type].keys
          end

          define_method("#{node_type}s_map") do
            nodes[node_type]
          end
        end

        def child_nodes_collections_list
          nodes[:child_nodes].keys
        end

        def child_nodes_collections_map
          nodes[:child_nodes]
        end

        private

        attr_reader :nodes

        def validate_node_definition(definition)
          values = definition.values.first
          raise InvalidNodeDefinition, 'invalid node definition' if values.keys.size != 2

          values.fetch(:type)
          values.fetch(:cascade)
        rescue KeyError => e
          raise InvalidNodeDefinition, "invalid node definition: #{e.message}"
        end
      end
    end
  end
end

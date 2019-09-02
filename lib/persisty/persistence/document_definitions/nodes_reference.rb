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

        def parent_node_for(klass)
          node_for(klass, :parent_node)
        end

        def child_node_for(klass)
          node_for(klass, :child_node)
        end

        def child_nodes_collection_for(klass)
          node_for(klass, :child_nodes_collection)
        end

        [:parent_node, :child_node, :child_nodes_collection].each do |node_type|
          node_type_key = node_type.to_s.sub('_collection', '').to_sym

          define_method("#{node_type}s_list") do
            nodes[node_type_key].keys
          end

          define_method("#{node_type}s_map") do
            nodes[node_type_key]
          end
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

        def node_for(klass, node_type)
          public_send("#{node_type}s_map").find(-> { [] }) do |_, node|
            node[:type] == klass
          end.first
        end
      end
    end
  end
end

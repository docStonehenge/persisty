module Persisty
  module Persistence
    module DocumentDefinitions
      class NodesReference
        class InvalidNodeKind < StandardError; end
        class InvalidNodeDefinition < StandardError; end

        attr_reader :nodes

        def initialize
          @nodes = { child_node: {}, child_nodes: {}, parent_node: {} }
        end

        def register(kind, node_definition)
          validate_node_definition(node_definition)
          nodes.fetch(kind).merge!(node_definition)
        rescue KeyError
          raise InvalidNodeKind, 'invalid node kind'
        end

        private

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

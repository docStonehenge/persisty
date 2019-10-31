module Persisty
  module Persistence
    module DocumentDefinitions
      class NodesReference
        extend Forwardable

        class InvalidNodeDefinition < StandardError; end

        class Node
          attr_reader :name, :class_name, :cascade, :foreign_key

          def initialize(node_definition)
            @name, @class_name, @cascade, @foreign_key = node_definition.values_at(
                                            :node, :class, :cascade, :foreign_key
                                          )
          end
        end

        def_delegators :@nodes, :keys, :key?, :has_key?, :values, :value?, :has_value?

        def initialize
          @nodes = {}
        end

        def register_parent(node_definition)
          validate_parent_node_definition(node_definition)
          validate_parent_already_registered(node_definition)
          @nodes[node_definition] = { child_node: [], child_nodes: [] }
        end

        %i[child_node child_nodes].each do |child_node_type|
          define_method("register_#{child_node_type}") do |parent_node, parent_class, child_node_definition|
            validate_child_node_definition(child_node_definition)

            parent_node_key, parent_node = find_registered_parent_for(
                               parent_node, parent_class
                             )

            validate_child_already_registered(
              parent_node_key, child_node_type, child_node_definition
            )

            parent_node[child_node_type] << child_node_definition
          end

          define_method("#{child_node_type}_for") do |parent_node, parent_class, child_class|
            nodes = find_registered_parent_for(parent_node, parent_class).last

            nodes[child_node_type].select do |node|
              node[:class] == child_class
            end.map { |node| Node.new(node) }
          end
        end

        def parent_node_for(node_name, klass)
          Node.new(find_registered_parent_for(node_name, klass).first)
        end

        private

        attr_reader :nodes

        def validate_parent_node_definition(definition)
          raise InvalidNodeDefinition, 'invalid node definition' if definition.size != 2
          validate_node_definition_keys(definition)
        end

        def validate_child_node_definition(definition)
          raise InvalidNodeDefinition, 'invalid node definition' if definition.size != 4

          validate_node_definition_keys(
            definition, node_specific_keys: %i[cascade foreign_key]
          )
        end

        def validate_node_definition_keys(definition, node_specific_keys: [])
          (%i[node class] + node_specific_keys).each(&definition.method(:fetch))
        rescue KeyError => e
          raise InvalidNodeDefinition, "invalid node definition: #{e.message}"
        end

        def validate_parent_already_registered(definition)
          return unless nodes.any? { |node, _| node[:node] == definition[:node] }

          raise InvalidNodeDefinition, 'parent definition already registered'
        end

        def find_registered_parent_for(node_name, klass)
          nodes.find(-> { raise Errors::NoParentNodeError }) do |key, _|
            key[:node] == node_name and key[:class] == klass
          end
        end

        def validate_child_already_registered(parent_node, child_node_type, definition)
          return if nodes.dig(parent_node, child_node_type).none? { |node| node[:node] == definition[:node] }

          raise InvalidNodeDefinition, "#{child_node_type} definition already registered"
        end
      end
    end
  end
end

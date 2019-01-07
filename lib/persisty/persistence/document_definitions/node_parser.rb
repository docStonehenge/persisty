module Persisty
  module Persistence
    module DocumentDefinitions
      class NodeParser
        attr_reader :node_name, :node_class

        def self.modifiers
          {
            underscorer: StringModifiers::Underscorer,
            camelizer: StringModifiers::Camelizer
          }
        end

        def self.new
          super(*modifiers)
        end

        def initialize(*string_modifiers)
          string_modifiers.each do |key, klass|
            instance_variable_set("@#{key}", klass.new)
          end
        end

        def parse_node_identification(name, class_name)
          self.node_name  = @underscorer.underscore(name)
          self.node_class = determine_node_class(class_name)
        end

        private

        attr_writer :node_name, :node_class

        def determine_node_class(class_name)
          Object.const_get(
            class_name ? class_name.to_s : modify_node_name
          )
        end

        def modify_node_name
          @camelizer.camelize(node_name.to_s)
        end
      end
    end
  end
end

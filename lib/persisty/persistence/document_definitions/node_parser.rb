module Persisty
  module Persistence
    module DocumentDefinitions
      class NodeParser
        attr_reader :node_name, :node_class

        def initialize(underscorer = StringModifiers::Underscorer.new, camelizer = StringModifiers::Camelizer.new)
          @underscorer = underscorer
          @camelizer   = camelizer
        end

        def parse_node_identification(name, class_name)
          self.node_name  = @underscorer.underscore(name)
          self.node_class = determine_node_class(class_name)
        end

        private

        attr_writer :node_name, :node_class

        def determine_node_class(class_name)
          Object.const_get(
            class_name ? class_name.to_s : @camelizer.camelize(node_name.to_s)
          )
        end
      end
    end
  end
end

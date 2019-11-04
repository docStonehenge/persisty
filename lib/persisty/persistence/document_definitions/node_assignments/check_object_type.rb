module Persisty
  module Persistence
    module DocumentDefinitions
      module NodeAssignments
        class CheckObjectType
          def self.call(node_class, node_name, object)
            return if object.nil? or object.is_a? node_class

            raise(
              TypeError,
              "Object is a type mismatch from defined node '#{node_name}'"
            )
          end
        end
      end
    end
  end
end

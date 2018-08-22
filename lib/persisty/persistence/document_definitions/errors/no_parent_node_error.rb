module Persisty
  module Persistence
    module DocumentDefinitions
      module Errors
        class NoParentNodeError < ArgumentError
          def initialize
            super(
              "Child node class must have a foreign_key field set for parent. "\
              "Use '.parent_node' method on child class to set correct parent_node relation."
            )
          end
        end
      end
    end
  end
end

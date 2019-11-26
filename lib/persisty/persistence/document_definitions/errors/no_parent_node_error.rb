module Persisty
  module Persistence
    module DocumentDefinitions
      module Errors
        class NoParentNodeError < ArgumentError
          def initialize
            super(
              "Class must have a parent correctly set up. "\
              "Use parent definition method on child class to set correct parent_node relation."
            )
          end
        end
      end
    end
  end
end

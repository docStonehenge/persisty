module Persisty
  module Persistence
    module Entities
      class ComparisonError < StandardError
        def initialize
          super("Cannot compare with an entity that isn't persisted.")
        end
      end
    end
  end
end

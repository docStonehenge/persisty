module Persisty
  module Persistence
    module DocumentDefinitions
      class CollectionNodeParser < NodeParser
        def self.modifiers
          super.merge(singularizer: StringModifiers::Singularizer)
        end

        private

        def modify_node_name
          @singularizer.singularize(super)
        end
      end
    end
  end
end

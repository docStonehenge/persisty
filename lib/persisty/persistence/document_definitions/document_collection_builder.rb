module Persisty
  module Persistence
    module DocumentDefinitions
      class DocumentCollectionBuilder
        def initialize(parent, node_name, node_class)
          @parent     = parent
          @node_name  = node_name
          @node_class = node_class
        end

        def build_collection(entities)
          collection = []
          entities   = entities.to_a

          @parent.public_send(@node_name).each do |entity|
            if entities.include?(entity)
              collection << entity
            else
              Persistence::UnitOfWork.current.register_removed(entity)
            end
          end

          document_collection_object_for collection + entities
        end

        private

        def document_collection_object_for(entities)
          DocumentCollectionFactory.collection_for(
            @node_class
          ).new(@parent, @node_class, entities)
        end
      end
    end
  end
end

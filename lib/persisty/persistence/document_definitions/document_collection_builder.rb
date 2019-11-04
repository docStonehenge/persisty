module Persisty
  module Persistence
    module DocumentDefinitions
      class DocumentCollectionBuilder
        def initialize(parent, document_collection, node_class)
          @parent              = parent
          @document_collection = document_collection
          @node_class          = node_class
        end

        def build_with(entities, foreign_key)
          with_valid_collection_object(entities) do |valid_collection|
            @document_collection.each do |entity|
              next if valid_collection.include?(entity)

              valid_collection.delete entity
              Persistence::UnitOfWork.current.register_removed(entity)
            end

            document_collection_object_for valid_collection, foreign_key
          end
        end

        private

        def with_valid_collection_object(entities)
          raise ArgumentError unless valid_collection_object?(entities)

          collection = entities.to_a.dup

          raise ArgumentError unless collection.all? { |e| e.is_a? @node_class }

          yield collection
        end

        def valid_collection_object?(collection)
          [NilClass, Array, document_collection_class].any? do |cls|
            collection.is_a? cls
          end
        end

        def document_collection_object_for(entities, foreign_key)
          document_collection_class.new(
            @parent, @node_class, foreign_key, entities
          )
        end

        def document_collection_class
          DocumentCollectionFactory.collection_for(@node_class)
        end
      end
    end
  end
end

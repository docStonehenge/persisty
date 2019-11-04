module Persisty
  module Persistence
    module DocumentDefinitions
      class DocumentCollectionFactory
        def self.collection_for(entity_class)
          Associations.const_get("#{entity_class}DocumentCollection")
        rescue NameError
          Associations.const_set(
            "#{entity_class}DocumentCollection",
            Class.new(Associations::DocumentCollection)
          )
        end
      end
    end
  end
end

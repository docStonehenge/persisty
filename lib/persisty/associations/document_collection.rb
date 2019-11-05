module Persisty
  module Associations
    class DocumentCollection
      def initialize(parent, document_class, foreign_key, entities = nil)
        @parent         = parent
        @document_class = document_class
        @foreign_key    = foreign_key
        @collection     = entities
      end

      def include?(entity)
        load_collection
        collection.include? entity
      end

      def reload
        collection&.each do |entity|
          Persistence::UnitOfWork.current.detach(entity)
        end

        self.collection = nil
        load_collection

        self
      end

      def _as_mongo_document
        all.map(&:_as_mongo_document)
      end

      def size
        load_collection
        collection.size
      end

      alias count size

      def push(entity)
        raise ArgumentError unless entity.is_a? @document_class
        load_collection

        return if include? entity

        collection << entity
        entity.assign_foreign_key(foreign_key, @parent.id)
        collection.sort! { |x, y| x <=> y }
      end

      alias << push

      def remove(entity)
        raise ArgumentError unless entity.is_a? @document_class
        load_collection

        return unless collection.delete(entity)

        register_removal_for entity
      end

      def all
        load_collection
        collection
      end

      alias to_a all

      def each(&block)
        load_collection
        collection.each(&block)
      end

      def [](index)
        load_collection
        collection[index]
      end

      def first
        return collection.first unless collection.nil?
        find_all_entities(limit: 1).first
      end

      def last
        return collection.last unless collection.nil?
        find_all_entities(sort: { _id: -1 }, limit: 1).last
      end

      private

      attr_accessor :collection

      def load_collection
        return unless collection.nil?
        self.collection = find_all_entities
      end

      def find_all_entities(**query_options)
        Repositories::Registry[@document_class].find_all(
          filter: { foreign_key => @parent.id }, **query_options
        )
      end

      def foreign_key
        (
          @foreign_key.present? ? @foreign_key : @parent.class.name.to_foreign_key
        ).to_sym
      end

      def register_removal_for(entity)
        entity_foreign_key = entity.public_send(foreign_key)
        return unless entity_foreign_key.nil? or entity_foreign_key == @parent.id
        Persistence::UnitOfWork.current.register_removed(entity)
      end
    end
  end
end

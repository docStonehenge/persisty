module Persisty
  module Associations
    class DocumentCollection
      def initialize(parent, document_class, collection = nil)
        @parent         = parent
        @document_class = document_class
        @collection     = collection
      end

      def reload
        @collection = nil
        load_collection
        self
      end

      def _as_mongo_document
        all.map(&:_as_mongo_document)
      end

      def size
        load_collection
        @collection.size
      end

      alias count size

      def all
        load_collection
        @collection
      end

      def each(&block)
        load_collection
        @collection.each(&block)
      end

      def [](index)
        load_collection
        @collection[index]
      end

      def first
        load_collection
        @collection.first
      end

      def last
        load_collection
        @collection.last
      end

      private

      def load_collection
        return unless @collection.nil?

        @collection = DocumentManager.new.find_all(
          @document_class, filter: { foreign_key => @parent.id }
        )
      end

      def foreign_key
        (
          StringModifiers::Underscorer.new.underscore("#{@parent.class}") + '_id'
        ).to_sym
      end
    end
  end
end

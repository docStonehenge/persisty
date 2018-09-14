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
        return @collection.first unless @collection.nil?
        find_all_entities(limit: 1).first
      end

      def last
        return @collection.last unless @collection.nil?
        find_all_entities(sort: { _id: -1 }, limit: 1).last
      end

      private

      def load_collection
        return unless @collection.nil?
        @collection = find_all_entities
      end

      def find_all_entities(**query_options)
        document_manager.find_all(
          @document_class,
          filter: { foreign_key => @parent.id }, **query_options
        )
      end

      def document_manager
        @document_manager ||= DocumentManager.new
      end

      def foreign_key
        (
          StringModifiers::Underscorer.new.underscore("#{@parent.class}") + '_id'
        ).to_sym
      end
    end
  end
end

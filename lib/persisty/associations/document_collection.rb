module Persisty
  module Associations
    class DocumentCollection
      def initialize(parent, collection, document_class)
        @parent         = parent
        @collection     = collection
        @document_class = document_class
      end

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
        return unless @collection.empty?

        @collection = Repositories::Registry[@document_class].find_all(
          filter: { foreign_key => @parent.id }
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

module Persisty
  module Associations
    class DocumentCollection
      def initialize(parent, document_class, entities = nil)
        @parent         = parent
        @document_class = document_class
        @collection     = entities
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
        load_collection

        unless collection.map(&:id).include? entity.id
          collection << entity
          collection.sort! { |x, y| x <=> y }
        end
      rescue Persistence::Entities::ComparisonError
      ensure
        collection
      end

      alias << push

      def all
        load_collection
        collection
      end

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
          StringModifiers::Underscorer.new.underscore("#{@parent.class}") + '_id'
        ).to_sym
      end
    end
  end
end

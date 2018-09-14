module Persisty
  module Repositories
    module Base
      # Initializes an instance of repository, receiving a call to set new or fetch
      # current connection from chosen database.
      # Determines <tt>collection_name</tt> and <tt>entity_klass</tt> attributes
      # based on repository classes that include this behavior.
      def initialize(client: Databases::MongoDB::Client.current_or_new_connection)
        @connection      = client
        @collection_name = collection_name
        @entity_klass    = entity_klass
      end

      def find(id)
        entity_id = BSON::ObjectId.try_convert(id)
        raise ArgumentError, "ID provided isn't a valid BSON::ObjectId" unless entity_id

        load_entity(entity_id) do
          if (query = get_entries({ _id: entity_id })).count.zero?
            raise EntityNotFoundError.new(id: entity_id, entity_name: @entity_klass.name)
          end

          query.first
        end
      end

      def find_all(filter: {}, **options)
        get_entries(filter, options).map do |entry|
          load_entity(entry.dig('_id')) { entry }
        end
      end

      def insert(entity)
        validate_entity_class    entity
        validate_entity_id_field entity

        trap_operation_error_as InsertionError do
          @connection.insert_on(@collection_name, entity._as_mongo_document)
        end
      end

      def update(entity)
        validate_entity_class    entity
        validate_entity_id_field entity

        trap_operation_error_as UpdateError do
          @connection.update_on(
            @collection_name, { _id: entity.id },
            '$set' => entity._as_mongo_document(include_id_field: false)
          )
        end
      end

      def delete(entity)
        validate_entity_class    entity
        validate_entity_id_field entity

        trap_operation_error_as DeleteError do
          @connection.delete_from(@collection_name, _id: entity.id)
        end
      end

      def aggregate(&block)
        @connection.aggregate_on(@collection_name, &block).entries
      end

      private

      def get_entries(filter, options = {}) # :nodoc:
        @connection.find_on(
          @collection_name, filter: filter.to_mongo_value, **options
        )
      end

      def load_entity(id) # :nodoc:
        if (loaded_entity = Persistence::UnitOfWork.current.get(@entity_klass, id))
          return loaded_entity
        end

        entry = yield

        Persistence::UnitOfWork.current.track_clean(@entity_klass.new(entry))
      end

      def validate_entity_class(entity) # :nodoc:
        return if entity.is_a? @entity_klass

        raise InvalidEntityError,
              "Entity must be of class: #{@entity_klass}. "\
              "This repository cannot operate on #{entity.class} entities."
      end

      def validate_entity_id_field(entity) # :nodoc:
        return if entity.id.present?
        raise InvalidEntityError, "Entity must have an 'id' field set."
      end

      def trap_operation_error_as(error_klass) # :nodoc:
        yield
      rescue Databases::OperationError => error
        raise error_klass, error.message
      end
    end
  end
end

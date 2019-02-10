module Persisty
  class DocumentManager
    def initialize
      connection    = Databases::MongoDB::Client.current_or_new_connection
      @id_generator = connection.id_generator

      begin
        unit_of_work
      rescue Persistence::UnitOfWorkNotStartedError
        start_new_unit_of_work
      end
    end

    def find(entity_type, entity_id)
      repository_for(entity_type).find(entity_id)
    end

    def find_all(entity_type, filter: {}, **options)
      repository_for(entity_type).find_all(filter: filter, **options)
    end

    def repository_for(entity_type)
      Repositories::Registry[entity_type]
    end

    def persist(entity)
      assign_new_id_to entity

      map_single_child_nodes_on(entity).each(&persist_child_operation_block(entity))

      operate_on_child_nodes_collections_from(
        entity, &persist_child_operation_block(entity)
      )

      unit_of_work.register_new entity
    end

    def remove(entity)
      removal_operation = lambda do |entity_to_be_removed|
        unit_of_work.register_removed entity_to_be_removed
      end

      removal_operation.call(entity)

      map_single_child_nodes_on(entity).each(&removal_operation)
      operate_on_child_nodes_collections_from(entity, &removal_operation)
    end

    def commit
      unit_of_work.commit
    ensure
      start_new_unit_of_work
    end

    def detach(entity)
      unit_of_work.detach entity
    end

    def clear
      unit_of_work.clear
    end

    private

    def unit_of_work
      Persistence::UnitOfWork.current
    end

    def start_new_unit_of_work
      Persistence::UnitOfWork.new_current
    end

    def assign_new_id_to(entity)
      entity.id = @id_generator.generate unless entity.id.present?
    end

    def map_single_child_nodes_on(entity)
      entity.child_nodes_list.map do |child_node|
        entity.public_send(child_node)
      end.compact
    end

    def operate_on_child_nodes_collections_from(entity, &block)
      entity.child_nodes_collections_list.map do |child_node_collection|
        entity.public_send(child_node_collection)
      end.each { |child_node_collection| child_node_collection.each(&block) }
    end

    def persist_child_operation_block(entity)
      lambda do |child|
        child.set_foreign_key_for(entity.class, entity.id)
        assign_new_id_to child
        unit_of_work.register_new child
      end
    end
  end
end

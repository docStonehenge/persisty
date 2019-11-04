module Persisty
  class DocumentManager
    def initialize
      connection    = Databases::MongoDB::Client.current_or_new_connection
      @id_generator = connection.id_generator
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
      cascade_persistence_on entity
      unit_of_work.register_new entity
    end

    def remove(entity)
      unit_of_work.register_removed entity

      entity.cascading_child_node_objects.each { |child| remove child }

      entity.cascading_child_nodes_objects.each do |collection|
        collection.each { |child| remove child }
      end
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

    def cascade_persistence_on(entity)
      entity.cascading_child_node_objects.each do |child|
        persist_child_for entity, child
      end

      entity.cascading_child_nodes_objects.each do |collection|
        collection.each do |child|
          persist_child_for entity, child
        end
      end
    end

    def persist_child_for(entity, child)
      child.set_foreign_key_for(entity.class, entity.id)
      assign_new_id_to child
      unit_of_work.register_new child
      cascade_persistence_on child
    end
  end
end

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

      map_single_child_nodes_on(entity).each do |child|
        child.set_foreign_key_for(entity.class, entity.id)
        assign_new_id_to child
        unit_of_work.register_new child
      end

      unit_of_work.register_new entity
    end

    def remove(entity)
      unit_of_work.register_removed entity

      map_single_child_nodes_on(entity).each do |child|
        unit_of_work.register_removed child
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

    def map_single_child_nodes_on(entity)
      entity.child_nodes_list.map do |child_node|
        entity.public_send(child_node)
      end.compact
    end
  end
end

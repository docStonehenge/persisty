module Persisty
  module Persistence
    module Entities
      class Registry
        attr_reader :entities

        # Initializes registry with a Hash <tt>entities</tt> serving as a map.
        def initialize
          @entities = {}
        end

        # Adds <tt>entity</tt> to <tt>entities</tt> with key as its class name and
        # database ID. Doesn't exchange entities with same ID if already present.
        def add(entity)
          return if include? entity
          entities[key_for(entity)] = entity
        end

        # Returns <tt>entity</tt> found on <tt>entities</tt> by class name and database ID
        # or nil if not found.
        def get(class_name, id)
          entities[entity_key(class_name, id)]
        end

        # Returns <tt>true</tt> if <tt>entities</tt> has key based on entity class and ID,
        # or <tt>false</tt> otherwise.
        def include?(entity)
          entities.include? key_for(entity)
        end

        # Removes <tt>entity</tt> from entites map and returns it, or returns nil
        # if entity isn't present.
        def delete(entity)
          entities.delete(key_for(entity))
        end

        # Removes all key-value pairs set on entities map.
        def clear
          entities.clear
        end

        private

        def key_for(entity)
          entity_key(entity.class.name, entity.id)
        end

        def entity_key(class_name, id) # :nodoc:
          "#{class_name.to_s.downcase}>>#{id}"
        end
      end
    end
  end
end

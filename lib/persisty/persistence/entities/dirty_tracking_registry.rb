module Persisty
  module Persistence
    module Entities
      class DirtyTrackingRegistry < Registry
        # Adds <tt>entity</tt> to <tt>entities</tt> with key as its class name and
        # database ID, splatting its attributes as a hash with each attribute name
        # as key and each value being an one-element array with the attribute
        # value only. Doesn't exchange entities with same ID if already present.
        def add(entity)
          return if include? entity

          entities[key_for(entity)] = map_attributes_from(
            entity
          ).each_with_object({}) { |(attr, value), track| track[attr] = [value] }
        end

        # Compares previously mapped attributes on <tt>entity</tt> and adds to
        # each attribute array only the value which has been changed.
        # DOES NOT add an untracked entity to <tt>entities</tt> and skips call
        # for an entity that isn't yet tracked.
        # If an attempt to register change before persisting previous changes is made,
        # it will register only last changes on each attribute.
        # Also, if an attempt to change and 'rollback' previous values on entity
        # (assigning new value, then assigning previous mapped value again),
        # it will not register a 'ghost' change; it will not add a change to same value
        # as previous.
        def register_changes_on(entity)
          return unless (track = get(entity.class, entity.id))

          new_attributes = map_attributes_from(entity)

          track.each do |attr, value_array|
            if value_array[0] == (new_value = new_attributes[attr])
              value_array.delete_at(1)
            else
              value_array[1] = new_value
            end
          end
        end

        # Returns hash of attributes on entity that have been changed, excluding
        # any attributes that haven't been mapped as changed.
        def changes_on(entity)
          get(
            entity.class, entity.id
          )&.reject { |_, value_array| value_array[1].nil? }
        end

        private

        def map_attributes_from(entity) # :nodoc:
          entity.to_hash(include_id_field: false)
        end
      end
    end
  end
end

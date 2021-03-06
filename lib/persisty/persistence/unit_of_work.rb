module Persisty
  module Persistence
    class UnitOfWork
      extend Forwardable

      # Sets a new instance of UnitOfWork as <tt>current_uow</tt> on running thread.
      # If a current UnitOfWork is present, uses entity registry set on it; if not,
      # calling .current will set a new UnitOfWork and this method will reset the
      # object on thread, using the registries already instantiated on .current.
      def self.new_current
        self.current = new(current.clean_entities, current.dirty_tracking)
      end

      # Sets an instance of UnitOfWork as <tt>current_uow</tt> on running thread.
      def self.current=(unit_of_work)
        Thread.current.thread_variable_set(:current_uow, unit_of_work)
      end

      # Returns <tt>current_uow</tt> UnitOfWork on running thread.
      # Starts a new unit of work if running thread doesn't have any.
      def self.current
        unless (current_uow = Thread.current.thread_variable_get(:current_uow))
          return self.current = new(Entities::Registry.new, Entities::DirtyTrackingRegistry.new)
        end

        current_uow
      end

      attr_reader :clean_entities, :dirty_tracking, :new_entities,
                  :changed_entities, :removed_entities

      def_delegator  :@clean_entities, :get
      def_delegators :@dirty_tracking, :register_changes_on, :refresh_changes_on, :changes_on

      # Initializes an instance with three new Set objects, an Entities::Registry
      # instance and an Entities::DirtyTrackingRegistry instance
      def initialize(entity_registry, dirty_tracking)
        @clean_entities   = entity_registry
        @dirty_tracking   = dirty_tracking
        @new_entities     = Set.new
        @changed_entities = Set.new
        @removed_entities = Set.new
      end

      def commit
        process_all_from new_entities, :insert do |entity|
          new_entities.delete entity
          track_clean entity
        end

        process_all_from changed_entities, :update do |entity|
          refresh_changes_on entity
        end

        process_all_from removed_entities, :delete
        true
      ensure
        Repositories::Registry.new_repositories
      end

      # Tries to delete entity from all lists on UnitOfWork, regardless if entity
      # is present or not on lists.
      def detach(entity)
        registration_lists.each { |list| list.delete entity }
      end

      # Tries to clear all registration lists on UnitOfWork, regardless if lists are already empty.
      def clear
        registration_lists.each(&:clear)
      end

      # Indicates whether an entity is managed by the UnitOfWork. An entity is considered
      # to be managed when it's present on UnitOfWork registration lists besides
      # the +removed_entities+ list.
      # Returns true if entity is present on such lists; false if it's present on
      # +removed_entities+ or if no registration lists include it.
      def managed?(entity)
        return false if removed_entities.include? entity
        present_on_lists? entity, registration_lists[0..2]
      end

      # Indicates whether an entity is detached from the UnitOfWork. An entity is considered
      # to be detached when no registration lists include it.
      # Returns true if entity isn't present on any of its lists; false if it's present
      # on at least one list.
      def detached?(entity)
        !present_on_lists? entity, registration_lists
      end

      def track_clean(entity)
        register_on(dirty_tracking, entity, ignore: registration_lists[3...4])
        register_clean(entity)
      end

      # Registers <tt>entity</tt> on clean entities map, avoiding duplicates.
      # Ingores entities without IDs, calls registration even if present on other lists.
      # Returns the +entity+ added or +nil+ if entity has no ID or it's a duplicate.
      #
      # Examples
      #
      #   register_clean(Foo.new(id: 123))
      #   # => <Foo:0x007f8b1a9028b8 @id=123, @amount=nil, @period=nil>
      def register_clean(entity)
        register_on(clean_entities, entity, ignore: registration_lists[1..4])
      end

      # Registers <tt>entity</tt> on new entities list and on clean entities, avoiding duplicates.
      # Ingores entities without IDs and if present on other lists.
      # Returns the +set+ with entity added or +nil+ if entity has no ID or it's a duplicate.
      #
      # Examples
      #
      #   register_new(Foo.new(id: 123))
      #   # => #<Set: {#<Foo:0x007f8b1a9028b8 @id=123, @amount=nil, @period=nil>}>
      def register_new(entity)
        register_on clean_entities, entity
        register_on new_entities, entity
      end

      # Registers <tt>entity</tt> on changed entities list, avoiding duplicates.
      # Also registers changes on dirty tracking map for <tt>entity</tt>.
      # Ingores entities without IDs and if present on other lists.
      # Returns the +set+ with entity added or +nil+ if entity has no ID or it's a duplicate.
      #
      # Examples
      #
      #   register_changed(Foo.new(id: 123))
      #   # => #<Set: {#<Foo:0x007f8b1a9028b8 @id=123, @amount=nil, @period=nil>}>
      def register_changed(entity)
        return unless register_as_changed?(entity)
        register_changes_on  entity
        changed_entities.add entity unless changes_on(entity).empty?
      end

      # Tries to remove <tt>entity</tt> from <tt>changed_entities</tt>, registers it
      # on removed entities list, removes from <tt>clean_entities</tt>, avoiding duplicates.
      # If it can remove from <tt>new_entities</tt>, it doesn't register on <tt>removed_entities</tt>.
      # Ingores entities without IDs.
      # Returns the +set+ with entity added or +nil+ if entity has no ID or it's a duplicate.
      #
      # Examples
      #
      #   register_removed(Foo.new(id: 123))
      #   # => #<Set: {#<Foo:0x007f8b1a9028b8 @id=123, @amount=nil, @period=nil>}>
      def register_removed(entity)
        changed_entities.delete entity
        dirty_tracking.delete   entity
        clean_entities.delete   entity

        return if new_entities.delete? entity

        register_on removed_entities, entity
      end

      private

      def process_all_from(list, process_name) # :nodoc:
        list.each do |entity|
          Repositories::Registry[entity.class].public_send(process_name, entity)
          yield entity if block_given?
        end
      end

      def registration_lists # :nodoc:
        [
          clean_entities, dirty_tracking, new_entities,
          changed_entities, removed_entities
        ]
      end

      def present_on_lists?(entity, lists_to_compare) # :nodoc:
        lists_to_compare.any? { |list| list.include? entity }
      end

      def register_on(list, entity, ignore: []) # :nodoc:
        return unless entity.id.present?
        return if present_on_persistent_lists?(entity, ignore)

        list.add entity
      end

      def present_on_persistent_lists?(entity, lists_to_ignore) # :nodoc:
        present_on_lists?(entity, (registration_lists[1..4] - lists_to_ignore))
      end

      def register_as_changed?(entity)
        entity.id.present? and
          dirty_tracking.include?(entity) and
          !present_on_persistent_lists?(entity, registration_lists.values_at(1, 3))
      end
    end
  end
end

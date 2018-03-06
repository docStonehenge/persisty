module Persisty
  module Repositories
    class Registry
      # Returns the repository object found by <tt>entity_type</tt>.
      # If not found by the first time called, sets a new object of repository type for <tt>entity_type</tt>
      # on map and returns it.
      # Returns nil if no repository is found for key.
      # It's a Thread-safe method, so it, at first, tries to get current Thread's registry
      # object and calls it; if no registry is found, it registers a new one on the Thread
      # to use it.
      def self.[](entity_type)
        (repositories or new_repositories)[entity_type]
      end

      # Registers a new Registry object into current Thread as <tt>repositories</tt>.
      def self.new_repositories
        Thread.current.thread_variable_set(:repositories, new)
      end

      # Returns the Registry object registered into current Thread as <tt>repositories</tt>.
      def self.repositories
        Thread.current.thread_variable_get(:repositories)
      end

      # Initializes registry object with an empty <tt>repositories</tt> Hash.
      def initialize
        @repositories = {}
      end

      # Returns the repository object found by <tt>entity_type</tt>.
      # If not found by the first time called, sets a new object of repository type for <tt>entity_type</tt>
      # on map and returns it.
      # Raises ArgumentError if entity_type doesn't respond to repository call.
      def [](entity_type)
        repository_name = entity_type.repository

        @repositories[repository_name].tap do |repository|
          unless repository
            return @repositories[repository_name] = repository_name.new
          end
        end

      rescue NoMethodError
        raise ArgumentError,
              "Entity class '#{entity_type}' doesn't respond to "\
              "#repository or isn't a entity type."
      end
    end
  end
end

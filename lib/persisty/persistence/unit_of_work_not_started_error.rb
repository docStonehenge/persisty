module Persisty
  module Persistence
    # A custom error object for every time when a call to current UnitOfWork is
    # attempted, but no instance is found.
    class UnitOfWorkNotStartedError < StandardError
      # Initializes a error object with custom message, indicating to start
      # a new UnitOfWork on current Thread.
      def initialize
        super(
          "There is no UnitOfWork started on running Thread. "\
          "To proper persist entities to the database, a new instance "\
          "is necessary. A call to UnitOfWork.new_current is needed."
        )
      end
    end
  end
end

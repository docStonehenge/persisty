module Persisty
  module Repositories
    class EntityNotFoundError < StandardError
      def initialize(id:, entity_name:)
        super("Unable to find #{entity_name} with ID ##{id}")
      end
    end
  end
end

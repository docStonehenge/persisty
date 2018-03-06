require 'mongo'

module Persisty
  module Databases
    module MongoDB
      class Client
        attr_reader :db_client, :id_generator

        # Returns current Thread already set client object or returns a new
        # client object set on Thread.
        def self.current_or_new_connection
          connection or new_connection
        end

        # Sets a new instance of Client as <tt>connection</tt> on running thread.
        def self.new_connection
          self.connection = new
        end

        # Sets an instance of Client as <tt>connection</tt> on running thread.
        def self.connection=(client)
          Thread.current.thread_variable_set(:connection, client)
        end

        # Returns <tt>connection</tt> Client on running thread.
        def self.connection
          Thread.current.thread_variable_get(:connection)
        end

        # Sets logger level and file for connections.
        def self.set_database_logging
          Mongo::Logger.logger       = ::Logger.new('log/mongodb.log')
          Mongo::Logger.logger.level = ::Logger::DEBUG
        end

        # Initializes instance with an <tt>id_generator</tt> object and a <tt>db_client</tt>
        # based on database file properties parsed.
        # Raises a Databases::ConnectionError if URI parsed is invalid.
        def initialize
          @id_generator = ::Mongo::Operation::ObjectIdGenerator.new

          @db_client    = ::Mongo::Client.new(
            Databases::URIParser.parse_based_on_file
          )
        rescue ::Mongo::Error::InvalidURI => e
          raise Databases::ConnectionError, e
        end

        # Returns results as a cursor of documents from collection, using provided filter and
        # sort options.
        def find_on(collection, filter: {}, sort: {})
          database_collection(collection).find(filter, sort: sort)
        end

        # Inserts document into named collection.
        # Raises Databases::OperationError if insertion fails.
        # Returns a Mongo::Operation::Result object indicating the number of insertions,
        # with acknowledgement.
        def insert_on(collection, document)
          trap_operation_error do
            database_collection(collection).insert_one(document)
          end
        end

        # Updates document into named collection, finding by <tt>identifier</tt>.
        # Raises Databases::OperationError if update fails.
        # Returns a Mongo::Operation::Result object indicating the number of documents modified,
        # with acknowledgement.
        def update_on(collection, identifier, document)
          trap_operation_error do
            database_collection(collection).update_one(identifier, document)
          end
        end

        # Removes document found by <tt>identifier</tt> from named collection.
        # Raises Databases::OperationError if deletion fails.
        # Returns a Mongo::Operation::Result object indicating the number of documents removed,
        # with acknowledgement.
        def delete_from(collection, identifier)
          trap_operation_error do
            database_collection(collection).delete_one(identifier)
          end
        end

        # Calls the aggregation pipeline into collection, receiving a block of
        # method calls to each corresponding pipeline stage.
        # The pipeline is mounted and ordered based on method calls ordering on block,
        # which will provide a array of stage hashes, using the aggregation wrapper object.
        # Returns a Mongo::Collection::View::Aggregation object.
        #
        # Examples
        #
        #  aggregate_on(:sample) do
        #    unwind :skus
        #    group { skuName: '$skus.name' }, { amount: { '$sum': '$skus.amount' } }
        #  end
        #
        #  #=> #<Mongo::Collection::View::Aggregation:0x007fb6131dd118
        #        @view=#<Mongo::Collection::View:0x70209990748720 namespace='test.sample' @filter={} @options={}>,
        #        @pipeline=[{:$unwind=>"skus"}, {:$group=>{:_id=>{:skuName=>"$skus.name"}, :amount=>{:$sum=>'$skus.amount'}}}], @options={}>
        def aggregate_on(collection, &block)
          database_collection(collection).aggregate(
            AggregationWrapper.new.tap do |wrapper|
              wrapper.instance_eval(&block)
            end.stages
          )
        end

        # Returns collection corresponding to the given <tt>name</tt>.
        def database_collection(name)
          db_client[name.to_sym]
        end

        private

        def trap_operation_error # :nodoc:
          yield
        rescue Mongo::Error => error
          raise Databases::OperationError, error.message
        end
      end
    end
  end
end

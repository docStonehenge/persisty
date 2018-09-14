require 'mongo'

module Persisty
  module Databases
    module MongoDB
      class Client
        LOG_LEVELS = {
          info: ::Logger::INFO, debug: ::Logger::DEBUG,
          unknown: ::Logger::UNKNOWN, fatal: ::Logger::FATAL,
          error: ::Logger::ERROR, warn: ::Logger::WARN
        }.freeze

        attr_reader :db_client, :id_generator

        class << self
          # Returns current Thread already set client object or returns a new
          # client object set on Thread.
          def current_or_new_connection
            connection or new_connection
          end

          # Sets a new instance of Client as <tt>connection</tt> on running thread.
          def new_connection
            self.connection = new
          end

          # Sets an instance of Client as <tt>connection</tt> on running thread.
          def connection=(client)
            Thread.current.thread_variable_set(:connection, client)
          end

          # Returns <tt>connection</tt> Client on running thread.
          def connection
            Thread.current.thread_variable_get(:connection)
          end

          # Sets logger level and file for connections, creating log/ directory
          # if it doesn't exist yet. Level values available: :info, :debug,
          # :unknown, :fatal, :error and :warn.
          # Raises an ArgumentError if <tt>level</tt> is invalid.
          def set_database_logging(level: :debug)
            unless Dir.exist?(log_file_dir = File.join(Dir.pwd, 'log'))
              Dir.mkdir(log_file_dir)
            end

            Mongo::Logger.logger = ::Logger.new(
              File.join(log_file_dir, "#{ENV['ENVIRONMENT']}.log")
            )

            Mongo::Logger.logger.level = logger_level_for(level)
          end

          private

          def logger_level_for(level_key)
            LOG_LEVELS.fetch(level_key)
          rescue KeyError
            raise ArgumentError
          end
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

        # Returns results as a cursor of documents from collection, using provided
        # options. Any invalid key or not received option as argument will be skipped.
        def find_on(collection, **options)
          filter = options.delete(:filter) || {}
          database_collection(collection).find(filter, options)
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

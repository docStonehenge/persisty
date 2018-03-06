module Persisty
  module Databases
    module MongoDB
      describe Client do
        include_context 'test database connection'

        let(:mongodb_client) { double(:client) }
        let(:logger)         { double(:logger) }
        let(:collection)     { double(:collection) }

        describe '.current_or_new_connection' do
          it 'returns current Thread connection when present' do
            expect(described_class).to receive(:connection).and_return mongodb_client
            expect(described_class.current_or_new_connection).to eql mongodb_client
          end

          it 'creates new client on current Thread when no other is present' do
            expect(described_class).to receive(:connection).and_return nil
            expect(described_class).to receive(:new_connection).and_return mongodb_client
            expect(described_class.current_or_new_connection).to eql mongodb_client
          end
        end

        describe '.new_connection' do
          it 'sets a new client instance as connection on current Thread' do
            allow(described_class).to receive(:new).and_return mongodb_client

            described_class.new_connection

            expect(Thread.current.thread_variable_get(:connection)).to equal mongodb_client
          end
        end

        describe '.connection= client' do
          it 'registers client object on current Thread as connection variable' do
            described_class.connection = mongodb_client
            expect(Thread.current.thread_variable_get(:connection)).to equal mongodb_client
          end
        end

        describe '.connection' do
          it 'returns connection variable set on current Thread' do
            described_class.connection = mongodb_client

            expect(described_class.connection).to equal mongodb_client
          end
        end

        describe '.set_database_logging' do
          before do
            allow(Mongo::Logger).to receive(:logger).and_return logger
          end

          it 'sets the default database logging to a log file' do
            log_file = double

            allow(::Logger).to receive(:new).once.with('log/mongodb.log').and_return log_file
            expect(Mongo::Logger).to receive(:logger=).with(log_file)
            expect(logger).to receive(:level=).with(::Logger::DEBUG)

            described_class.set_database_logging
          end
        end

        describe '#initialize' do
          let(:id_gen) { double(:id_gen) }

          before do
            expect(
              Databases::URIParser
            ).to receive(:parse_based_on_file).once.and_return 'uri'
          end

          it 'sets DB connection and ID generator' do
            expect(::Mongo::Client).to receive(:new).with(
                                         'uri'
                                       ).and_return mongodb_client

            expect(
              ::Mongo::Operation::ObjectIdGenerator
            ).to receive(:new).once.and_return id_gen

            subject = described_class.new

            expect(subject.db_client).to eql mongodb_client
            expect(subject.id_generator).to eql id_gen
          end

          it 'raises ConnectionError if MongoDB client receives an invalid URI' do
            exception = Mongo::Error::InvalidURI.new('foo', 'details')

            expect(::Mongo::Client).to receive(:new).with('uri').and_raise exception

            expect {
              described_class.new
            }.to raise_error(
                   Databases::ConnectionError,
                   "Error while connecting to database. Details: #{exception.message}"
                 )
          end
        end

        describe '#find_on collection, filter: {}, sort: {}' do
          before do
            expect(::Mongo::Client).to receive(:new).with(
                                         'mongodb://127.0.0.1:27017/dummy_db'
                                       ).and_return mongodb_client

            expect(subject).to receive(
                                 :database_collection
                               ).once.with('foo').and_return collection
          end

          context 'when sort options argument is empty' do
            it 'calls find on collection using empty filter and returns entries' do
              expect(collection).to receive(:find).once.with(
                                      {}, { sort: {} }
                                    ).and_return [{"foo" => "bar"}]

              expect(subject.find_on('foo')).to eql([{ 'foo' => 'bar' }])
            end

            it 'calls find on collection using filter and returns entries' do
              expect(collection).to receive(:find).once.with(
                                      { '_id' => '123' }, { sort: {} }
                                    ).and_return [{"foo" => "bar"}]

              expect(
                subject.find_on('foo', filter: { '_id' => '123' })
              ).to eql [{"foo" => "bar"}]
            end
          end

          context 'when sort options argument is present' do
            it 'calls find on collection using empty filter and returns entries' do
              expect(collection).to receive(:find).once.with(
                                      {}, { sort: { foo: :asc } }
                                    ).and_return [{"foo" => "bar"}]

              expect(
                subject.find_on('foo', sort: { foo: :asc })
              ).to eql([{ 'foo' => 'bar' }])
            end

            it 'calls find on collection using filter and returns entries' do
              expect(collection).to receive(:find).once.with(
                                      { '_id' => '123' }, { sort: { foo: :asc } }
                                    ).and_return [{"foo" => "bar"}]

              expect(
                subject.find_on('foo', filter: { '_id' => '123' }, sort: { foo: :asc })
              ).to eql [{"foo" => "bar"}]
            end
          end
        end

        describe '#insert_on collection, document' do
          before do
            expect(::Mongo::Client).to receive(:new).with(
                                         'mongodb://127.0.0.1:27017/dummy_db'
                                       ).and_return mongodb_client

            expect(subject).to receive(
                                 :database_collection
                               ).once.with('foo').and_return collection
          end

          it 'calls single document insertion on collection' do
            expect(collection).to receive(:insert_one).once.with(
                                    foo: 'bar', bar: 'bazz'
                                  )

            subject.insert_on('foo', foo: 'bar', bar: 'bazz')
          end

          it 'raises Databases::OperationError when operation raises Mongo error' do
            expect(collection).to receive(:insert_one).once.with(
                                    foo: 'bar', bar: 'bazz'
                                  ).and_raise Mongo::Error, 'Error'

            expect {
              subject.insert_on('foo', foo: 'bar', bar: 'bazz')
            }.to raise_error(Databases::OperationError, 'Error')
          end
        end

        describe '#update_on collection, identifier, document' do
          before do
            expect(::Mongo::Client).to receive(:new).with(
                                         'mongodb://127.0.0.1:27017/dummy_db'
                                       ).and_return mongodb_client

            expect(subject).to receive(
                                 :database_collection
                               ).once.with('foo').and_return collection
          end

          it 'calls single document update, using identifier to fetch on collection' do
            expect(collection).to receive(:update_one).once.with(
                                    { name: 'Foo' }, { field: '2' }
                                  )

            subject.update_on('foo', { name: 'Foo' }, { field: '2' })
          end

          it 'raises Databases::OperationError when operation raises Mongo error' do
            expect(collection).to receive(:update_one).once.with(
                                    { name: 'Foo' }, { field: '2' }
                                  ).and_raise Mongo::Error, 'Error'

            expect {
              subject.update_on('foo', { name: 'Foo' }, { field: '2' })
            }.to raise_error(Databases::OperationError, 'Error')
          end
        end

        describe '#delete_from collection, identifier' do
          before do
            expect(::Mongo::Client).to receive(:new).with(
                                         'mongodb://127.0.0.1:27017/dummy_db'
                                       ).and_return mongodb_client

            expect(subject).to receive(
                                 :database_collection
                               ).once.with('foo').and_return collection
          end

          it 'calls single document delete using identifier to find it' do
            expect(collection).to receive(:delete_one).once.with({ name: 'Foo' })
            subject.delete_from('foo', { name: 'Foo' })
          end

          it 'raises Databases::OperationError when operation raises Mongo error' do
            expect(collection).to receive(:delete_one).once.with(
                                    { name: 'Foo' }
                                  ).and_raise Mongo::Error, 'Error'

            expect {
              subject.delete_from('foo', { name: 'Foo' })
            }.to raise_error(Databases::OperationError, 'Error')
          end
        end

        describe '#aggregate_on collection, &block' do
          let(:aggregation_result) { double }

          before do
            expect(::Mongo::Client).to receive(:new).with(
                                         'mongodb://127.0.0.1:27017/dummy_db'
                                       ).and_return mongodb_client

            expect(subject).to receive(
                                 :database_collection
                               ).once.with('foo').and_return collection
          end

          it 'calls aggregate pipeline method on collection, using block into aggregation wrapper' do
            expect(collection).to receive(:aggregate).once.with(
                                    [
                                      { :$group => { _id: 'Sum', sum: { :$sum => '$amount' } } }
                                    ]
                                  ).and_return aggregation_result

            expect(
              subject.aggregate_on('foo') do
                group 'Sum', { sum: { :$sum => '$amount' } }
              end
            ).to eql aggregation_result
          end
        end

        describe '#database_collection name' do
          before do
            expect(::Mongo::Client).to receive(:new).with(
                                         'mongodb://127.0.0.1:27017/dummy_db'
                                       ).and_return mongodb_client
          end

          it 'returns collection based on name, fetched as key from db connection' do
            expect(subject.db_client).to receive(:[]).once.with(:foo).and_return collection

            expect(
              subject.database_collection(:foo)
            ).to eql collection
          end
        end
      end
    end
  end
end

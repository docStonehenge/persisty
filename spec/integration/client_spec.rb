describe 'Databases::MongoDB::Client integration tests', db_integration: true do
  subject { Persisty::Databases::MongoDB::Client.new }

  it 'sets the default database logging to a log file' do
    temp_log_dir = "#{Dir.pwd}/log"
    FileUtils.mkdir(temp_log_dir)

    log_file = File.new("#{temp_log_dir}/mongodb.log", 'w+')

    Persisty::Databases::MongoDB::Client.set_database_logging
    expect(Mongo::Logger.logger).to be_debug

    log_file.close
    FileUtils.rm_rf(temp_log_dir)
  end

  describe 'starting real connection' do
    before do
      Mongo::Logger.logger.level = Logger::INFO
    end

    it 'sets connection object into current Thread only' do
      Persisty::Databases::MongoDB::Client.connection = subject
      expect(Persisty::Databases::MongoDB::Client.connection).to equal subject

      client_variable = "client_variable"

      Thread.new do
        client_variable = Persisty::Databases::MongoDB::Client.connection
      end.join

      expect(client_variable).to be_nil
    end

    it 'sets a new connection object into current Thread' do
      Persisty::Databases::MongoDB::Client.new_connection

      expect(
        Persisty::Databases::MongoDB::Client.connection
      ).to be_an_instance_of Persisty::Databases::MongoDB::Client

      client_variable = "client_variable"

      Thread.new do
        client_variable = Persisty::Databases::MongoDB::Client.connection
      end.join

      expect(client_variable).to be_nil
    end

    it 'connects correctly to database using properties file' do
      expect(subject.db_client.database.name).to eql 'dummy_db'
    end
  end

  describe 'fetching collection correctly' do
    before do
      Mongo::Logger.logger.level = Logger::INFO
    end

    it 'returns collection based on name, fetched as key from db connection' do
      collection = subject.database_collection(:test_collection)

      expect(collection).to be_an_instance_of(Mongo::Collection)
      expect(collection.name).to eql 'test_collection'
    end
  end

  describe 'insertions' do
    it 'correctly inserts document on collection without previous id set' do
      result = subject.insert_on(:test_collection, a: 'foo')
      expect(result).to be_ok
      expect(result.written_count).to eql 1
    end

    it 'correctly inserts document on collection with previous set id' do
      new_id = subject.id_generator.generate

      result = subject.insert_on(:test_collection, _id: new_id, a: 'foo')
      expect(result).to be_ok
      expect(result.written_count).to eql 1
    end

    it 'raises Databases::OperationError when insertion with same id is attempted' do
      new_id = subject.id_generator.generate

      subject.insert_on(:test_collection, _id: new_id, a: 'foo')

      expect {
        subject.insert_on(:test_collection, _id: new_id, a: 'bar')
      }.to raise_error(Persisty::Databases::OperationError)
    end
  end

  describe 'querying' do
    before do
      subject.insert_on(:test_collection, a: 'foo')
      subject.insert_on(:test_collection, a: 'bar')
      subject.insert_on(:test_collection, a: 'bazz')
    end

    it 'correctly returns documents found on collection' do
      result = subject.find_on(:test_collection)

      expect(result.count).not_to be_zero

      result = result.entries
      expect(result[0]).to include('a' => 'foo')
      expect(result[1]).to include('a' => 'bar')
      expect(result[2]).to include('a' => 'bazz')
    end

    it 'correctly returns documents filtered' do
      result = subject.find_on(:test_collection, filter: { a: { '$regex' => 'ba' } })

      expect(result.count).not_to be_zero

      result = result.entries
      expect(result[0]).to include('a' => 'bar')
      expect(result[1]).to include('a' => 'bazz')
    end

    it 'correctly returns documents sorted' do
      result = subject.find_on(:test_collection, sort: { a: 1 })

      expect(result.count).not_to be_zero

      result = result.entries
      expect(result[0]).to include('a' => 'bar')
      expect(result[1]).to include('a' => 'bazz')
      expect(result[2]).to include('a' => 'foo')
    end

    it 'correctly returns documents filtered and sorted' do
      result = subject.find_on(
        :test_collection, filter: { a: { '$regex' => 'ba' } }, sort: { a: -1 }
      )

      expect(result.count).not_to be_zero

      result = result.entries
      expect(result[0]).to include('a' => 'bazz')
      expect(result[1]).to include('a' => 'bar')
    end
  end

  describe 'updating' do
    before do
      @id = subject.id_generator.generate
      subject.insert_on(:test_collection, _id: @id, a: 'foo')
    end

    it 'correctly updates a document found on collection by identifier' do
      result = subject.update_on(
        :test_collection, { _id: @id }, { '$set' => { a: 'fooza' } }
      )

      expect(result).to be_ok
      expect(result.modified_count).to eql 1
    end

    it 'raises Databases::OperationError when update fails' do
      expect {
        subject.update_on(:test_collection, @id, { '$set' => { a: 'fooza' } })
      }.to raise_error(Persisty::Databases::OperationError)
    end

    it "doesn't raise error and doesn't modify document not found" do
      result = subject.update_on(
        :test_collection, { _id: 123 }, { '$set' => { a: 'fooza' } }
      )

      expect(result).to be_ok
      expect(result.modified_count).to eql 0
    end
  end

  describe 'deleting' do
    before do
      @id = subject.id_generator.generate
      subject.insert_on(:test_collection, _id: @id, a: 'foo')
    end

    it 'correctly deletes a document found on collection by identifier' do
      result = subject.delete_from(:test_collection, _id: @id)

      expect(result).to be_ok
      expect(result.deleted_count).to eql 1
    end

    it 'raises Databases::OperationError when deletion fails' do
      expect {
        subject.delete_from(:test_collection, @id)
      }.to raise_error(Persisty::Databases::OperationError)
    end

    it "doesn't raise error and doesn't delete document not found" do
      result = subject.delete_from(:test_collection, _id: 123)

      expect(result).to be_ok
      expect(result.deleted_count).to eql 0
    end
  end

  describe 'aggregating' do
    before do
      subject.insert_on(:test_collection, a: 'foo', fruits: ['apple', 'pear'])
      subject.insert_on(:test_collection, a: 'bar', fruits: ['pineapple', 'pear', 'tomato'])
      subject.insert_on(:test_collection, a: 'bazz', fruits: ['grape', 'pear', 'apple', 'tomato'])
    end

    it 'returns correct aggregation object to operate on its entries' do
      agg = subject.aggregate_on(:test_collection) do
        unwind :fruits
        group '$fruits', { count: { :$sum => 1 } }
      end

      expect(agg.entries).to eql(
                               [
                                 { "_id" => "grape", "count" => 1 },
                                 { "_id" => "pineapple", "count" => 1 },
                                 { "_id" => "pear", "count" => 3 },
                                 { "_id" => "tomato", "count" => 2 },
                                 { "_id" => "apple", "count" => 2 }
                               ]
                             )
    end
  end

  after do
    Thread.current.thread_variable_set(:connection, nil)
    subject.db_client.close
  end
end

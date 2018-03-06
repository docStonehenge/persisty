require 'database_cleaner'

RSpec.configure do |config|
  config.include ConnectionDefinitions

  database_setup = lambda do
    client = Mongo::Client.new(
      Persisty::Databases::URIParser.parse_based_on_file
    )

    DatabaseCleaner[:mongo].db = client.database

    client.close
  end

  config.before(:suite) do
    DatabaseCleaner[:mongo].strategy = :truncation
  end

  config.before(:each, :db_integration) do
    @stdout_clone = $stdout
    $stdout = File.open(File::NULL, 'w')

    prepare_for_database_connection
    database_setup.call

    DatabaseCleaner[:mongo].start
  end

  config.after(:each, :db_integration) do
    database_setup.call
    DatabaseCleaner[:mongo].clean
    clear_database_connection_settings
    $stdout = @stdout_clone
  end
end

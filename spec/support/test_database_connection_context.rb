shared_context 'test database connection' do
  RSpec.configure { |config| config.include ConnectionDefinitions }

  before { prepare_for_database_connection }
  after { clear_database_connection_settings }
end

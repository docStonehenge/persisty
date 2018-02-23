shared_context 'test database connection' do
  before do
    ENV['ENVIRONMENT'] = 'test'
    ENV['PROTOCOL'] = 'mongodb'
    ENV['HOST']     = '127.0.0.1'
    ENV['PORT']     = '27017'

    @temp_db_dir = "#{Dir.pwd}/db"
    FileUtils.mkdir(@temp_db_dir)

    FileUtils.cp(
      File.join(Dir.pwd, 'spec/support/dummy_db_properties.yml'),
      File.join(@temp_db_dir, 'properties.yml')
    )
  end

  after do
    FileUtils.rm_rf(@temp_db_dir)
    ENV['ENVIRONMENT'] = nil
    ENV['PROTOCOL']    = nil
    ENV['HOST']        = nil
    ENV['PORT']        = nil
  end
end

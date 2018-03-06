require 'fileutils'

module Persisty
  module Databases
    describe URIParser do
      include_context 'test database connection'

      describe '.parse_based_on_file' do
        it 'returns correct URI after reading properties from yml file' do
          expect(
            described_class.parse_based_on_file
          ).to eql 'mongodb://127.0.0.1:27017/dummy_db'
        end

        it 'raises ConnectionPropertiesError if cannot read properties file' do
          expect(File).to receive(:read).once.with(
                            "#{Dir.pwd}/db/properties.yml"
                          ).and_raise Errno::ENOENT

          expect {
            described_class.parse_based_on_file
          }.to raise_error(
                 Databases::ConnectionPropertiesError,
                 'Error while loading db/properties.yml file. Make sure that all key-value pairs are correctly set or file exists.'
               )
        end

        it "raises ConnectionPropertiesError if fetching properties from file isn't possible" do
          expect(File).to receive(:read).once.with(
                            "#{Dir.pwd}/db/properties.yml"
                          ).and_return ""

          expect {
            described_class.parse_based_on_file
          }.to raise_error(
                 Databases::ConnectionPropertiesError,
                 'Error while loading db/properties.yml file. Make sure that all key-value pairs are correctly set or file exists.'
               )
        end
      end
    end
  end
end

module Persisty
  module Databases
    describe ConnectionPropertiesError do
      it '#message' do
        expect(
          subject.message
        ).to eql "Error while loading db/properties.yml file. Make sure "\
                 "that all key-value pairs are correctly set or file exists."
      end
    end
  end
end

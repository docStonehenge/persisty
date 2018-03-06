describe 'String class extension' do
  describe '#to_mongo_value' do
    it 'returns itself' do
      expect("foo".to_mongo_value).to eql "foo"
      expect("".to_mongo_value).to eql ""
    end
  end

  describe '#present?' do
    it 'is present when it has at least one character besides a whitespace' do
      expect(" foo").to be_present
      expect(".").to be_present
      expect("f 1 @").to be_present
      expect("さくぶん").to be_present
    end

    it "isn't present when it is just whitespace or an empty string" do
      expect('').not_to be_present
      expect(' ').not_to be_present
      expect('       ').not_to be_present
      expect("\n").not_to be_present
      expect("\n\t").not_to be_present
      expect("\n\s").not_to be_present
      expect("\s").not_to be_present
      expect("\s\t").not_to be_present
      expect("\t").not_to be_present
    end
  end
end

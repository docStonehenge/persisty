describe 'Array class extension' do
  describe '#to_mongo_value' do
    it 'returns itself when empty' do
      expect([].to_mongo_value).to eql []
    end

    it 'returns array with all values mapped to mongo values' do
      expect(
        [BigDecimal("100"), Date.parse("2017/11/21"), 123].to_mongo_value
      ).to eql [100.0, Date.parse("2017/11/21"), 123]
    end

    it 'returns value mapped to nil when it cannot be transformed to a mongo value' do
      Foo = Struct.new(:field)

      expect(
        [Foo.new, 123].to_mongo_value
      ).to eql [nil, 123]
    end
  end

  describe '#present?' do
    it 'is present when array has at least one value' do
      expect([1]).to be_present
      expect([[]]).to be_present
      expect([[], []]).to be_present
    end

    it "isn't present when array is empty" do
      expect([]).not_to be_present
    end
  end
end

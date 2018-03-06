describe 'Hash class extension' do
  describe '#to_mongo_value' do
    it 'returns itself when Hash is empty' do
      expect({}.to_mongo_value).to eql({})
    end

    it 'returns itself with all values being transformed to mongo values' do
      expect(
        {
          foo: "bar", "amount" => BigDecimal.new("459.90"), [1] => Date.parse('2017/01/01')
        }.to_mongo_value
      ).to eql(foo: 'bar', 'amount' => 459.9, [1] => Date.parse('2017/01/01'))
    end

    it 'transforms value to nil if value cannot be transformed to mongo value' do
      Test = Struct.new(:field)

      expect({foo: Test.new(field: "hello")}.to_mongo_value).to eql(foo: nil)
    end
  end

  describe '#present?' do
    it 'is present when it has at least when key-value pair' do
      expect(a: 'b').to be_present
      expect(nil => nil).to be_present
    end

    it "isn't present when it is empty" do
      expect({}).not_to be_present
    end
  end
end

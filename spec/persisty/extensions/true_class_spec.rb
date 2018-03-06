describe 'TrueClass extension' do
  describe '#to_mongo_value' do
    it 'returns itself' do
      expect(true.to_mongo_value).to eql true
    end
  end

  it '#present?' do
    expect(true).to be_present
  end
end

describe 'FalseClass extension' do
  describe '#to_mongo_value' do
    it 'returns itself' do
      expect(false.to_mongo_value).to eql false
    end
  end

  it '#present?' do
    expect(false).not_to be_present
  end
end

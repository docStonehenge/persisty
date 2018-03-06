describe 'NilClass extension' do
  describe '#to_mongo_value' do
    it 'returns itself' do
      expect(nil.to_mongo_value).to eql nil
    end
  end

  it '#present?' do
    expect(nil).not_to be_present
  end
end

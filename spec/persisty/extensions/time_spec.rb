describe 'Time class extension' do
  describe '.try_convert value' do
    context 'when value is a valid date' do
      it 'returns Time object' do
        expect(Time.try_convert("2017/01/01")).to be_an_instance_of Time
        expect(Time.try_convert(Time.now)).to be_an_instance_of Time
      end
    end

    context 'when value argument is invalid' do
      it 'returns nil' do
        expect(Time.try_convert("2017")).to be_nil
        expect(Time.try_convert("")).to be_nil
      end
    end

    context 'when argument type is not conversible' do
      it 'returns nil' do
        expect(Time.try_convert(nil)).to be_nil
        expect(Time.try_convert(1)).to be_nil
      end
    end
  end

  describe '#to_mongo_value' do
    it 'returns itself' do
      value = Time.now
      expect(value.to_mongo_value).to eql value
    end
  end

  it '#present?' do
    expect(Time.now).to be_present
  end
end

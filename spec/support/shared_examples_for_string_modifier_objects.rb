shared_examples_for 'a StringModifier object' do
  it { is_expected.to be_a Persisty::StringModifiers::Base }
  it { is_expected.to respond_to :modify }
end

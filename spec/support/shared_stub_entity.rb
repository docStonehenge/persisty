shared_context 'StubEntity' do
  class ::StubEntity < OpenStruct; end

  let(:entity) { ::StubEntity.new }
end

shared_context 'StubRepository' do
  class ::StubRepository; end

  let(:repo) { ::StubRepository.new }
end

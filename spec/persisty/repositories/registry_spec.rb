module Persisty
  module Repositories
    describe Registry do
      include_context 'StubRepository'

      let(:entity) { double(:entity, repository: StubRepository) }

      let(:repo) { ::StubRepository.new }

      describe '.[] class_name' do
        context 'when no registry is set yet on current Thread' do
          it 'calls new registry and returns the repository object set for class' do
            Thread.current.instance_variables.delete(:repositories)
            expect(described_class[entity]).to be_an_instance_of StubRepository
          end
        end

        it 'returns the repository object set for entity class' do
          expect(described_class[entity]).to be_an_instance_of StubRepository
        end

        it 'returns always the same repository object for class' do
          repository = described_class[entity]

          expect(described_class[entity]).to equal repository
          expect(described_class[entity]).to equal repository
        end
      end

      describe '.new_repositories' do
        it 'sets a new Registry object into current Thread as repositories variable' do
          described_class.new_repositories

          expect(
            Thread.current.thread_variable_get(:repositories)
          ).to be_an_instance_of(described_class)
        end
      end

      describe '.repositories' do
        it 'gets Registry object registered in current Thread' do
          registry = described_class.new

          Thread.current.thread_variable_set(:repositories, registry)

          expect(described_class.repositories).to equal registry
        end
      end

      describe '#[] class_name' do
        it 'returns the repository object set for entity class' do
          subject.instance_variable_get(
            :@repositories
          )[repo.class] = repo

          expect(subject[entity]).to equal repo
        end

        it 'returns always the same repository object for class' do
          subject.instance_variable_get(
            :@repositories
          )[repo.class] = repo

          expect(subject[entity]).to equal repo
          expect(subject[entity]).to equal repo
        end

        context 'when no repository is yet set for class name' do
          before do
            expect(
              subject.instance_variable_get(:@repositories)[entity]
            ).to be_nil
          end

          it 'returns a new repository object' do
            expect(subject[entity]).to be_an_instance_of(StubRepository)
          end

          it 'returns the same repository object' do
            repo = subject[entity]

            expect(repo).to be_an_instance_of(StubRepository)
            expect(subject[entity]).to equal repo
            expect(subject[entity]).to equal repo
          end

          it 'raises ArgumentError if entity type does not contain a repository method' do
            expect {
              subject[String]
            }.to raise_error(
                   ArgumentError,
                   "Entity class 'String' doesn't respond to #repository or isn't a entity type."
                 )
          end
        end
      end
    end
  end
end

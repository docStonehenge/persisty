module Persisty
  module Databases
    module MongoDB
      describe AggregationWrapper do
        it { is_expected.to have_attributes(stages: []) }

        describe '#project specifications' do
          it 'puts a Hash with $project key pointing to specifications into stages' do
            subject.project(foo: true)
            expect(subject.stages).to include(:$project => { foo: true })
          end
        end

        describe '#match specifications' do
          it 'puts a Hash with $match key pointing to specifications into stages' do
            subject.match(foo: 'name')
            expect(subject.stages).to include(:$match => { foo: 'name' })
          end
        end

        describe '#redact specifications' do
          it 'puts a Hash with $redact key pointing to specifications into stages' do
            subject.redact(foo: 'name')
            expect(subject.stages).to include(:$redact => { foo: 'name' })
          end
        end

        describe '#limit specifications' do
          it 'puts a Hash with $limit key pointing to limit number into stages' do
            subject.limit(3)
            expect(subject.stages).to include(:$limit => 3)
          end
        end

        describe '#skip specifications' do
          it 'puts a Hash with $skip key pointing to skip number into stages' do
            subject.skip(3)
            expect(subject.stages).to include(:$skip => 3)
          end
        end

        describe '#unwind field_name' do
          it 'puts a Hash with $unwind key pointing to unwinding field into stages' do
            subject.unwind(:field)
            expect(subject.stages).to include(:$unwind => '$field')
          end
        end

        describe '#group expression_id, grouping_expression' do
          it 'puts a Hash with $group key pointing to group process into stages' do
            subject.group(
              { period: '$date_of_birth' },
              { avg_salary: { '$avg' => '$amount' } }
            )

            expect(subject.stages).to include(
                                        :$group => {
                                          _id: { period: '$date_of_birth' },
                                          avg_salary: { '$avg' => '$amount' }
                                        }
                                      )
          end
        end

        describe '#sample sample_size' do
          it 'puts a Hash with $sample key pointing to sizing document into stages' do
            subject.sample(3)
            expect(subject.stages).to include(:$sample => { size: 3 })
          end
        end

        describe '#sort specifications' do
          it 'puts a Hash with $sort key pointing to sorting document into stages' do
            subject.sort(field1: -1)
            expect(subject.stages).to include(:$sort => { field1: -1 })
          end
        end

        describe '#geo_near spherical: false, distance_field:, near:, other_fields' do
          context 'using spherical default value' do
            it 'puts a Hash with $geoNear key pointing to specifications with spherical false' do
              subject.geo_near(
                include: { limit: 200 }, distance_field: 'distance',
                near: [20, 30]
              )

              expect(subject.stages).to include(
                                          :$geoNear => {
                                            spherical: false,
                                            distanceField: 'distance',
                                            near: [20, 30],
                                            limit: 200
                                          }
                                        )
            end
          end

          context 'using spherical option as true' do
            it 'puts a Hash with $geoNear key pointing to specifications with spherical true' do
              subject.geo_near(
                spherical: true, distance_field: 'distance', near: [20, 30]
              )

              expect(subject.stages).to include(
                                          :$geoNear => {
                                            spherical: true,
                                            distanceField: 'distance',
                                            near: [20, 30]
                                          }
                                        )
            end
          end
        end

        describe '#lookup from:, local_field:, foreign_field:, as:' do
          it 'puts a Hash with $lookup key pointing to specifications document' do
            subject.lookup(
              from: 'another_collection',
              local_field: 'field1',
              foreign_field: 'field2',
              as: 'array_field'
            )

            expect(subject.stages).to include(
                                        :$lookup => {
                                          from: 'another_collection',
                                          localField: 'field1',
                                          foreignField: 'field2',
                                          as: 'array_field'
                                        }
                                      )
          end
        end

        describe '#out specifications' do
          it 'puts a Hash with $out key pointing to out collection name into stages' do
            subject.out('new_collection')
            expect(subject.stages).to include(:$out => 'new_collection')
          end
        end

        describe '#index_stats' do
          it 'puts a Hash with $indexStats key pointing to empty document into stages' do
            subject.index_stats
            expect(subject.stages).to include(:$indexStats => {})
          end
        end
      end
    end
  end
end

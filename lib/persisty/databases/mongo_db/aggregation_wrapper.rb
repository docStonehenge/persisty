module Persisty
  module Databases
    module MongoDB
      class AggregationWrapper
        attr_reader :stages

        instance_eval do
          [:project, :match, :redact, :limit, :skip, :sort, :out].each do |stage|
            define_method(stage) do |specifications|
              push_stage_as stage, specifications
            end
          end
        end

        def initialize
          @stages = []
        end

        def unwind(field_name)
          push_stage_as :unwind, "$#{field_name}"
        end

        def group(expression_id, grouping_expression)
          push_stage_as(
            :group,
            { _id: expression_id }.merge(grouping_expression)
          )
        end

        def sample(sample_size)
          push_stage_as :sample, size: sample_size
        end

        def geo_near(spherical: false, distance_field:, near:, include: {})
          push_stage_as(
            :geoNear,
            {
              spherical: spherical, distanceField: distance_field, near: near
            }.merge(include)
          )
        end

        def lookup(from:, local_field:, foreign_field:, as:)
          push_stage_as(
            :lookup,
            from: from, localField: local_field,
            foreignField: foreign_field, as: as
          )
        end

        def index_stats
          push_stage_as :indexStats, {}
        end

        private

        def push_stage_as(stage_name, specifications)
          @stages << { :"$#{stage_name}" => specifications }
        end
      end
    end
  end
end

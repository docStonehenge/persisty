require "persisty/version"

module Persisty
  require 'persisty/extensions/float'
  require 'persisty/extensions/array'
  require 'persisty/extensions/hash'
  require 'persisty/extensions/string'
  require 'persisty/extensions/integer'
  require 'persisty/extensions/boolean'
  require 'persisty/extensions/false_class'
  require 'persisty/extensions/true_class'
  require 'persisty/extensions/nil_class'
  require 'persisty/extensions/date'
  require 'persisty/extensions/time'
  require 'persisty/extensions/big_decimal'
  require 'persisty/extensions/bson_object_id'

  require 'persisty/databases/connection_properties_error'
  require 'persisty/databases/operation_error'
  require 'persisty/databases/connection_error'
  require 'persisty/databases/uri_parser'
  require 'persisty/databases/mongo_db/aggregation_wrapper'
  require 'persisty/databases/mongo_db/client'

  require 'persisty/persistence/unit_of_work_not_started_error'
  require 'persisty/persistence/unit_of_work'
  require 'persisty/persistence/entities/registry'
  require 'persisty/persistence/entities/field'

  require 'persisty/repositories/registry'
end

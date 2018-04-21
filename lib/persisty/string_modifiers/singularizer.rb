require 'persisty/string_modifiers/base'

module Persisty
  module StringModifiers
    class Singularizer < Base
      alias singularize modify

      private

      def define_modification_rules
        {
          default: {
            /s$/i => '', /([^aeiou])ies$/i => '\1y',
            /(bus)(es)?$/i => '\1', /([^aeiou]ch|x|sh|z|ss)es$/i => '\1',
            /([aeiou]ch)s$/i => '\1', /([aeiou])ves$/i => '\1fe',
            /([^aeiou])ves$/i => '\1f', /(f)s$/i => '\1',
            /(o)s$/i => '\1', /(o)es/i => '\1',
            /(p)eople$/i => '\1erson', /(child)ren$/i => '\1',
            /(zombie)s$/i => '\1', /(p)erson$/i => '\1erson',
            /(child)$/i => '\1', /(zombie)$/i => '\1'
          }
        }
      end
    end
  end
end

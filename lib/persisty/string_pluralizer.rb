module Persisty
  # A helper object to provide correct plurals to words.
  # It's initialized with a map of Regexp=>String key-value pairs, which is just
  # an approximation to start working with pluralizations on repository names.
  class StringPluralizer
    def initialize
      @pluralizations = {
        default: {
          /(p)erson/i => '\1eople', /(child)$/i => '\1ren', /(zombie)$/i => '\1s',
          /(?!<[^aeiou]{1}>)y$/i => 'ies', /(epo|stoma)ch$/i => '\\0s',
          /(ss|x|ch|sh|z)$/i => '\1es', /(bu)s$/i => '\\0es',
          /\w*[aeiou]ch$/i => '\\0s',
          /(?!<[aeiou]{1}>)fe$|(?<![aeiou])f$/i => '\1ves',
          /(?<![^aeiou]{1})f$/i => '\\0s', /(tomat|potat|her)o$/i => '\\0es',
          /\w*o$/i => '\\0s', /s$/i => 's'
        }
      }
    end

    # Pluralizes <tt>word</tt> according to locale set (it uses 'default' locale as default.)
    # Tries to pluralize word following English rules of pluralization. Any word
    # that doesn't match any specific rules are just modified with an appended 's'.
    # If word is already pluralized, it's not modified.
    def pluralize(word, locale: :default)
      plurals = @pluralizations[locale.to_sym]
      plural = word.to_s.dup

      return plural if word.empty?

      if (key = plurals.keys.find { |rule| rule.match(word) })
        plural.sub!(/#{Regexp.new(key.to_s)}/, plurals.fetch(key))
      end

      plural
    end
  end
end

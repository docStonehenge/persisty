module Persisty
  class Boolean
    def self.try_convert(value)
      return true if  value == true
      return false if value == false
      nil
    end
  end
end

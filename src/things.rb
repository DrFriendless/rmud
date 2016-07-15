class ThingClass
  def initialize(w, k, p, rc)
    @wizard = w
    @key = k
    @properties = p
    @rubyClass= rc
  end

  def instantiate
    obj = @rubyClass.new
    obj.instance_variable_set(:@thingClass, self)
    @properties.each {
      |k,v| obj.instance_variable_set("@"+k, v)
    }
    obj
  end
end

# A thing in the world
class Thing
  @thingClass

  attr_reader :short
  attr_reader :long
end

module Singleton

end

module Container
  @contents = []
end

class Body < Thing
  include Container
end

class PlayerBody < Body
end

class Room < Thing
  include Container
  include Singleton
end
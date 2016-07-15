require_relative './things'

class World
  def initialize()
    @singletons = []
    @thingClasses = []
  end

  def load_lib()
    yml = Psych.load_file("lib/lib.yml")
    yml.each {
        |k,v| load_from_file("lib", k, v)
    }
  end

  def load_from_file(wizard, key, props)
    fields = key.split("/")
    className = fields[0]
    key = fields[1]
    clazz = Object::const_get(className)
    thingClass = ThingClass.new(wizard, key, props, clazz)
    @thingClasses.push thingClass
    if clazz.ancestors.include? Singleton
      obj = thingClass.instantiate
      p obj.long
      @singletons.push obj
    end
  end
end

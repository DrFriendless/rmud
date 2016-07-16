require_relative './things'
require_relative './lib'

class World
  def initialize()
    @singletons = []
    @thingClasses = {}
  end

  def load_lib()
    yml = Psych.load_file("lib/lib.yml")
    yml.each {
        |k,v| load_from_file("lib", k, v)
    }
    @singletons.each { |t| t.loaded_from_file() }
  end

  def load_from_file(wizard, key, props)
    fields = key.split("/")
    tcr = ThingClassRef.new(wizard, key)
    tc = tcr.thingclass(self, props)
    @thingClasses[tcr.key] = tc
    if tc.rubyClass.ancestors.include? Singleton
      obj = tc.instantiate
      @singletons.push obj
    end
  end

  def persist()
    data = {}
    @singletons.each {
        |s| s.persist(data)
    }
    p data
  end

  def instantiate(thingclassref)
    @thingClasses[thingclassref.key].instantiate
  end
end

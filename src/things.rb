class ThingClass
  def initialize(tcr, p, rc, world)
    @thing_class_ref = tcr
    @properties = p
    @ruby_class= rc
    @world = world
  end

  attr_reader :properties
  attr_reader :ruby_class
  attr_reader :world
  attr_reader :thing_class_ref

  def wizard()
    @thing_class_ref.wizard
  end

  def instantiate
    obj = @ruby_class.new
    obj.instance_variable_set(:@thingClass, self)
    @properties.each {
      |k,v| obj.instance_variable_set("@"+k, v)
    }
    obj
  end

  def persistence_key()
    @thing_class_ref.key
  end
end

class ThingClassRef
  def initialize(w, s)
    fields = s.split("/")
    @wizard = fields[-3] || w
    @clazz = fields[-2]
    @id = fields[-1]
  end

  attr_reader :wizard

  def key()
    "#{@wizard}/#{@clazz}/#{@id}"
  end

  def thingclass(world, props)
    clazz = Object::const_get(@clazz)
    ThingClass.new(self, props, clazz, world)
  end
end

# A thing in the world
class Thing
  @thingClass
  @location

  attr_reader :short
  attr_reader :long

  def persist(data)
    data[persistence_key] = {} unless data[persistence_key]
  end

  def restore(data, by_persistence_key)
  end

  def persistence_key()
    @thingClass.persistence_key + "@#{object_id}"
  end

  def move_to(dest)
    if @location
      @location.remove(self)
    end
    @location = ()
    if dest
      dest.receive(self)
    end
    @location = dest
  end

  def create(s)
    tcr = ThingClassRef.new(@thingClass.wizard, s)
    @thingClass.world.instantiate(tcr)
  end
end

# marker to indicate that there is one of these and it always exists.
module Singleton
  def persistence_key()
    @thingClass.persistence_key
  end
end

module Container
  def initialize_contents()
    @contents = []
  end

  def persist_contents(data)
    data[persistence_key] = {} unless data[persistence_key]
    data[persistence_key][:contents] = @contents.map { |t| t.persistence_key }
  end

  def restore_contents(data, by_persistence_key)
    contents = data[:contents]
    contents.each { |key|
      if by_persistence_key[key]
        by_persistence_key[key].move_to(self)
      else
        puts "Did not find #{key}"
      end
    }
  end

  def remove(thing)
    if @contents.include? thing
      @contents.delete thing
    end
  end

  def receive(thing)
    if !@contents.include? thing
      @contents.push thing
    end
  end
end


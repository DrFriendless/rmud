# Code related to Things. The Thing class is big and gets its own file.

# properties that should not be set by the YAML.
BANNED_PROPERTIES = %w(contents verbs)

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

  def wizard
    @thing_class_ref.wizard
  end

  def instantiate
    obj = @ruby_class.new
    obj.instance_variable_set(:@thingClass, self)
    BANNED_PROPERTIES.each { |p| @properties.delete(p) }
    @properties.each { |k,v|
      obj.instance_variable_set("@#{k}", v)
    }
    obj.after_properties_set
    obj
  end

  def persistence_key
    @thing_class_ref.key
  end

  def is?(tcr)
    @thing_class_ref.key == tcr.key
  end
end

class ThingClassRef
  def initialize(w, s)
    fields = s.split("/")
    @wizard = fields[-3] || w
    @clazz = fields[-2]
    @id = fields[-1]
    @key = "#{@wizard}/#{@clazz}/#{@id}"
  end

  attr_reader :wizard
  attr_reader :key

  def singleton?
    clazz = Object::const_get(@clazz)
    clazz.included_modules.include?(Singleton)
  end

  def thingclass(world, props)
    clazz = Object::const_get(@clazz)
    ThingClass.new(self, props, clazz, world)
  end

  def to_s
    key
  end
end


# marker to indicate that there is one of these and it always exists.
module Singleton
  def persistence_key
    class_name
  end
end

module Container
  def initialize_contents
    @contents = []
  end

  attr_reader :contents

  def persist_contents(data)
    data[:contents] = @contents.
        select { |t| !t.do_not_persist? }.
        map { |t| t.persistence_key }
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

  def find(name)
    @contents.each { |thing|
      if thing.is_called?(name); return thing end
    }
    false
  end

  def find_by_class(tcr)
    @contents.each { |thing|
      if thing.of_class?(tcr); return thing end
    }
    false
  end

  def remove_from_container(thing)
    if @contents.include? thing
      @contents.delete thing
    end
  end

  def receive_into_container(thing)
    if !@contents.include? thing
      @contents.push thing
    end
  end
end

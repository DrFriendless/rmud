# A thing in the world

class Thing
  def initialize()
    @verbs = []
    verb(["examine", :it]) { |response, command, match|
      if examine
        response.message = examine
        response.handled = true
      elsif long
        response.message = long
        response.handled = true
      end
    }
  end

  # properties loaded from YAML have been set
  def after_properties_set()
  end

  attr_reader :short
  attr_reader :long
  attr_accessor :location
  attr_reader :examine
  attr_reader :identity
  attr_reader :value
  attr_reader :weight
  attr_reader :verbs

  def is_called?(name)
    if @identity && !@identities
      @identities = @identity.split(",").map { |i| i.strip }
    end
    @identities && @identities.include?(name)
  end

  def of_class?(tcr)
    @thingClass.is?(tcr)
  end

  def persist(data)
    data[persistence_key] ||= {}
  end

  def restore(data, by_persistence_key)
  end

  def persistence_key()
    @thingClass.persistence_key + "@#{object_id}"
  end

  def world()
    @thingClass.world
  end

  def move_to_location(key)
    loc = world.find_singleton(key) || world.find_singleton("lib/Room/lostandfound")
    move_to(loc)
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

  def method_missing(method, *args)
    puts "#{method} missing from #{self}"
    #begin
    #  5/0
    #rescue => exception
    #  puts exception.backtrace
    #  raise # always reraise
    #end
    # now we can try to get dogs to quack.
  end

  def verb(pattern, &block)
    @verbs.push(Verb.new(pattern, block))
  end

  def alias_verb(pattern1, pattern2)
    @verbs.each { |v|
      if v.pattern == pattern2
        verb(pattern1, &v.block)
        return
      end
    }
  end

  def handle(response, command)
    if !@verbs; return () end
    @verbs.each { |v|
      match = v.match(command, self)
      if match; v.handle(response, command, match) end
      if response.handled; return response end
    }
  end

  def destination(v)
    if v && v.count("/") == 1
      @thingClass.wizard + "/" + v
    else
      v
    end
  end

  def carriable?()
    false
  end

  def is_do_not_persist?()
    false
  end

  def heartbeat(time, time_of_day)
  end

  def a_short
    # todo - a/an
    "a #{short}"
  end

  def destroy
    world.destroy self
  end
end

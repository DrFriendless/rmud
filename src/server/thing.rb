# A thing in the world

class Thing
  def initialize()
    @verbs = []
    verb(["get", :it]) { |response,command,match|
      if @location == command.body.location
        if self.can_be_carried?
          self.move_to(command.body)
          # todo tell the room
        else
          response.message = "You can't take that."
        end
        response.handled = true
      end
    }
    alias_verb(["take", :it], ["get", :it])
    verb(["drop", :it]) { |response,command,match|
      if @location == command.body
        self.move_to(command.body.location)
        # todo tell the room
      else
        response.message = "You don't have that."
      end
      response.handled = true
    }
  end

  # properties loaded from YAML have been set
  def after_properties_set()
  end

  attr_accessor :short
  attr_accessor :long
  attr_accessor :location
  attr_accessor :identity

  def is_called?(name)
    if @identity && !@identities
      @identities = @identity.split(",").each { |i| i.strip() }
    end
    @identities && @identities.include?(name)
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

  def create(s)
    tcr = ThingClassRef.new(@thingClass.wizard, s)
    world.instantiate_ref(tcr)
  end

  def method_missing(method, *args)
    puts method
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

  def can_be_carried?()
    true
  end

  def is_do_not_persist?()
    false
  end

  def heartbeat(time, time_of_day)
  end
end
require_relative './verb'

# A thing in the world

class Thing
  def initialize
    @verbs = []
  end

  # properties loaded from YAML have been set
  def after_properties_set
    verb(["examine", :it]) { |response, command, match|
      p "handled by the wrong examine #{match[0]}"
      response.message = long
      response.handled = true
    }
  end

  attr_reader :short
  attr_reader :long
  attr_accessor :location
  attr_reader :identity
  attr_reader :value
  attr_reader :weight
  attr_reader :verbs

  def is_called?(name)
    if @identity && !@identities
      @identities = @identity.split(',').map { |i| i.strip.downcase }
    end
    (@identities && @identities.include?(name.downcase)) || (short && short.downcase == name.downcase)
  end

  def of_class?(tcr)
    @thingClass.is?(tcr)
  end

  def persist(data)
    data[persistence_key] ||= {}
  end

  def restore(data, by_persistence_key)
  end

  def persistence_key
    @thingClass.persistence_key + "@#{object_id}"
  end

  def world
    @thingClass.world
  end

  def wizard
    @thingClass.wizard
  end

  def move_to_location(key)
    loc = world.find_singleton(key) || world.find_singleton("lib/Room/lostandfound")
    move_to(loc)
  end

  def move_to(dest)
    if @location
      @location.remove_from_container(self)
    end
    @location = nil
    if dest
      dest.receive_into_container(self)
    end
    @location = dest
  end

  def method_missing(method, *args)
    puts "#{method} missing from #{self}"
    #begin
    #  5/0
    #rescue => exception
    #  puts exception.backtrace
    #end
    # now we can try to get dogs to quack.
  end

  def verb(pattern, &block)
    @verbs.push(Verb.new(pattern, block))
  end

  def alias_verb(pattern1, pattern2)
    @verbs.reverse.each { |v|
      if v.pattern == pattern2
        verb(pattern1, &v.block)
        return
      end
    }
  end

  def handle(response, command)
    return nil unless @verbs
    @verbs.reverse.each { |v|
      match = v.match(command, self)
      if match; v.handle(response, command, match) end
      if response.handled; return response end
    }
  end

  def local_dest(v)
    world.dest(@thingClass.wizard, v)
  end

  def carriable?
    false
  end

  def do_not_persist?
    false
  end

  def heartbeat(time, time_of_day)
  end

  def a_short
    # todo - a/an
    "a #{short}"
  end

  def destroy
    if @contents
      @contents.each { |c|
        if c.short
          c.move_to(@location)
        else
          world.destroy(c)
        end
      }
    end
    world.destroy(self)
  end

  # we noticed something happen
  def effect(effect)
  end

  # periodically refresh ourselves
  def reset
  end
end

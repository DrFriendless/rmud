require_relative './verb'

# A thing in the world

class Thing
  def initialize
    @verbs = []
  end

  # properties loaded from YAML have been set
  def after_properties_set
    require_relative './verb_funcs'
    instance_variables.each { |name|
      if name.to_s.end_with?('_it')
        v = name.to_s[1..-4]
        var = instance_variable_get(name)
        if var.is_a?(String)
          f = eval(var, binding)
          verb([v, :it]) { |response, command, match| f.call(response, command, match) }
        elsif var.is_a? Array
          funcs = var.map { |f| eval(f, binding) }
          verb([v, :it]) { |response, command, match|
            funcs.each { |func|
              func.call(response, command, match)
            }
          }
        end
      end
    }
  end

  attr_reader :short
  attr_reader :long
  attr_accessor :location
  attr_reader :identity
  attr_writer :identities
  attr_reader :value
  attr_reader :weight
  attr_reader :verbs

  def calc_identities
    if @identity && !@identities
      @identities = @identity.split(',').map { |i| i.strip.downcase }
    end
  end

  def is_called?(name)
    calc_identities
    (@identities && @identities.include?(name.downcase)) || (short && short.downcase == name.downcase)
  end

  def of_class?(tcr)
    @thingClass.is?(tcr)
  end

  def persist(data)
  end

  def restore(data, by_persistence_key)
  end

  def persistence_key
    class_name + "@#{object_id}"
  end

  def class_name
    @thingClass.persistence_key
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
    world.dest(wizard, v)
  end

  def carriable?
    false
  end

  def do_not_persist?
    false
  end

  def heartbeat(time, time_of_day)
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

  def lightsource?
    @lightsource
  end
end

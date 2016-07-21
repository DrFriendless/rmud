require_relative '../../src/server/thingutil.rb'
require_relative '../../src/server/thing.rb'

class Body < Thing
  include Container

  def initialize()
    super
    initialize_contents
  end

  def persist(data)
    super
    persist_contents(data)
    data[persistence_key] ||= {}
    data[persistence_key][:maxhp] = @maxhp
    data[persistence_key][:hp] = @hp
  end

  def restore(data, by_persistence_key)
    super
    restore_contents(data, by_persistence_key)
    @maxhp = data[:maxhp]
    @hp = data[:hp]
  end

  def can_be_carried?()
    false
  end
end

# A PlayerBody is special because it can appear and disappear as players log in and out.
class PlayerBody < Body
  attr_accessor :name
  attr_accessor :loc

  def initialize()
    super
    @loc = "lib/Room/lostandfound"
    verb(["look"]) { |response, command, match|
      response.handled = true
      lines = []
      # no reason this should happen, but if it does...
      if !@location
        puts "Emergency moving #{@name} to the library."
        move_to_location("lib/Room/library")
      end
      if @location.lit?
        lines.push(@location.long)
        @location.contents.each { |t|
          if t != self
            lines.push(t.long)
          end
        }
        response.message = lines.join("\n")
      else
        response.message = "It's dark and you can't see a thing."
      end
    }
    verb(["quit"]) { |response, command, match|
      response.handled = true
      response.quit = true
    }
    verb(["inventory"]) { |response, command, match|
      response.handled = true
      lines = @contents.map { |c| c.short }
      if lines.size == 0; lines.push("You don't have anything.") end
      response.message = lines.join("\n")
    }
    alias_verb(["i"], ["inventory"])
  end

  def is_do_not_persist?()
    return true
  end

  def persistence_key()
    "player/#{@name}"
  end

  def persist(data)
    super
    if @location
      data[persistence_key][:loc] = @location.persistence_key
      data[persistence_key][:name] = @name
    end
  end
end

class Creature < Body
end

class Room < Thing
  include Container
  include Singleton

  def initialize()
    super
    initialize_contents
    @lit = false
  end

  def after_properties_set()
    direction(:west, :w)
    direction(:east, :e)
    direction(:north, :n)
    direction(:south, :s)
    direction(:out)
    direction(:in)
    direction(:up, :u)
    direction(:down, :d)
  end

  def direction(key, alt=())
    v = instance_variable_get("@#{key}")
    if v && v.count("/") == 1
      v = @thingClass.wizard + "/" + v
      instance_variable_set("@#{key}", v)
    end
    if v
      verb(["#{key}"]) { |response, command, match|
        # todo notify the room
        command.body.move_to_location(v)
        response.handled = true
        response.direction = true
      }
    else
      # we don't define that direction, but we do know it is a direction so mark it as such.
      verb(["#{key}"]) { |response, command, match|
        response.direction = true
      }
    end
    if alt; alias_verb(["#{alt}"], ["#{key}"]) end
  end

  def persist(data)
    super
    persist_contents(data)
  end

  def restore(data, by_persistence_key)
    super
    restore_contents(data, by_persistence_key)
  end

  def on_world_create()
    cs = @thingClass.properties["contains"]
    if cs then
      refs = cs.split()
      refs.map { |rs|
        create(rs).move_to(self)
      }
    end
  end

  def can_be_carried?()
    false
  end

  def lit?()
    @lit == true || @lit == "true"
  end
end

class Outdoor < Room
  def lit?()
    # todo - base on game time
    true
  end
end
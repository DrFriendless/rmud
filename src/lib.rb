require_relative './thingutil.rb'
require_relative './thing.rb'

class Body < Thing
  include Container

  def initialize()
    super
    initialize_contents
  end

  def persist(data)
    super
    persist_contents(data)
    data[persistence_key] = {} unless data[persistence_key]
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
  def initialize()
    super
    verb(["look"]) { |response, command, match|
      response.handled = true
      lines = []
      # no reason this should happen, but if it does...
      if !@location
        puts "Emergency moving #{@name} to the library."
        move_to_location("lib/Room/library")
      end
      lines.push(@location.long)
      @location.contents.each { |t|
        if t != self
          lines.push(t.long)
        end
      }
      response.message = lines.join("\n")
    }
    verb(["quit"]) { |response, command, match|
      response.handled = true
      response.quit = true
    }
    verb(["inventory"]) { |response, command, match|
      response.handled = true
      puts "contents #{@contents}"
      lines = @contents.map { |c| c.short }
      if lines.size == 0; lines.push("You don't have anything.") end
      response.message = lines.join("\n")
    }
    alias_verb(["i"], ["inventory"])
  end

  def persistence_key()
    "lib/PlayerBody/#{name}"
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
end
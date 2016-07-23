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

  def go_to(location)
    # TODO - departure effect
    self.move_to_location(location)
    # TODO - arrival effect
  end

  def carriable?()
    false
  end
end

# A PlayerBody is special because it can appear and disappear as players log in and out.
class PlayerBody < Body
  attr_accessor :name
  attr_accessor :loc
  attr_accessor :effect_callback

  def initialize()
    super()
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
    verb(["time"]) { |response, command, match|
      response.handled = true
      tod = world.time_of_day
      response.message =
          case tod
            when 0..39; "It's dawn."
            when 40..119; "It's morning."
            when 120..219; "It's the middle of the day."
            when 220..299; "It's afternoon."
            when 300..339; "It's dusk."
            when 340..419; "It's evening."
            when 420..519; "It's the middle of the night."
            when 520..599; "It's some time before dawn."
            else "Time has gone kind of wibbly-wobbly."
          end
    }
    verb(["inventory"]) { |response, command, match|
      response.handled = true
      lines = @contents.map { |c| c.short }.select {|c| c }
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

  def effect(effect)
    if @effect_callback
      @effect_callback.effect(effect)
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
        command.body.go_to(v)
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

  def carriable?()
    false
  end

  def lit?()
    @lit == true || @lit == "true"
  end
end

# a thing that can't be seen but can define verbs
class Virtual < Thing
  # properties loaded from YAML have been set
  def after_properties_set()
    if @examine_it
      verb(["examine", :it]) { |response, command, match|
        response.message = @examine_it
        response.handled = true
      }
    end
    if @climb_it_no
      verb(["climb", :it]) { |response, command, match|
        response.message = @climb_it_no
        response.handled = true
      }
    end
    if @climb_it_yes
      @climb_it_yes = destination(@climb_it_yes)
      verb(["climb", :it]) { |response, command, match|
        command.body.go_to(@climb_it_yes)
        response.handled = true
      }
    end
    if @enter_it
      @enter_it = destination(@enter_it)
      verb(["enter", :it]) { |response, command, match|
        command.body.go_to(@enter_it)
        response.handled = true
      }
    end
    if @enter
      @enter = destination(@enter)
      verb(["enter", :it]) { |response, command, match|
        command.body.go_to(@enter)
        response.handled = true
      }
    end
  end

  def short
    ()
  end

  def long
    ()
  end
end
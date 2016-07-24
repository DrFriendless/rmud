require_relative '../../src/server/thingutil.rb'
require_relative '../../src/server/thing.rb'
require_relative '../../src/shared/effects.rb'

class Body < Thing
  include Container
  include EffectObserver
  attr_accessor :hp
  attr_accessor :maxhp

  def initialize()
    super
    initialize_contents
    @wear_slots = {"necklace" => [()], "hat" => [()], "ring" => [(), ()],
                   "right hand" => [()], "left hand" => [()], "shoes" => [()]}
  end

  def wear_slots(slot)
    p slot
    p @wear_slots
    @wear_slots[slot] || []
  end

  def wearing?(obj)
    wear_slots(obj.slot).include?(obj)
  end

  def injured()
    @hp < @maxhp
  end

  def damage(n)
    @hp -= n
    # TODO check for death
  end

  def heal(n)
    if @hp < @maxhp
      @hp += n
      if @hp > @maxhp; @hp = @maxhp end
      if @hp == @maxhp
        tell("You feel better now.")
      end
    end
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

  def go_to(location, direction)
    self.location.publish_to_room(LeaveEffect.new(self, direction))
    self.move_to_location(location)
    self.location.publish_to_room(ArriveEffect.new(self))
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

  def tell(message)
    ob = Observation.new(message)
    @effect_callback.effect(ob)
  end
end

class Creature < Body
end

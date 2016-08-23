require_relative './mangrove'
require_relative '../../src/shared/effects'
require_relative '../lib/body'

DRAGON = "mangrove/GreenDragon/default"

class OutsideDragonLair < Outdoor
  def publish_to_room(effect)
    super
    if effect.is_a? ArriveEffect
      victim = effect.actor
      captured_loc = world.find_singleton("mangrove/CapturedByDragon/default")
      lair_loc = world.find_singleton("mangrove/DragonLair/default")
      return unless (victim.is_a? Body) && lair_loc.dragon_available?
      dragon = world.find_singleton(DRAGON)
      dragon.move_to(self)
      super(TellRoom.new(dragon, "You hear a tremendous roar, and the earth shakes!"))
      super(ArriveEffect.new(dragon))
      super(CaptureByDragonEffect.new(dragon, victim))
      dragon.move_to(captured_loc)
      victim.move_to(captured_loc)
      captured_loc.time_of_capture = world.time
    end
  end
end

class CaptureByDragonEffect < ActorActorEffect
  def initialize(dragon, victim)
    super(dragon, victim, nil, "The dragon grabs you in its claws and lifts you into the sky!",
          "The dragon grabs #{victim.name}, and with a flap of its mighty wings, launches them both into the sky!")
  end
end

class TellDragonStoryEffect < Effect
  def initialize(dragon, message)
    @dragon = dragon
    @msg = message
  end

  def message_for(observer)
    Observation.new(@msg) unless observer == @dragon
  end
end

class CapturedByDragon < Outdoor
  attr_writer :time_of_capture

  def heartbeat(time, time_of_day)
    dragon = world.find_singleton(DRAGON)
    lair_loc = world.find_singleton("mangrove/DragonLair/default")
    unless @time_of_capture
      @contents.each { |c| c.move_to(lair_loc) }
      return
    end
    victims = contents.select { |c| (c.is_a? Body) && c != dragon }
    if victims.length == 0
      @time_of_capture = 0
      return
    end
    i = time - @time_of_capture
    if i < @story.length
      s = @story[i]&.strip
      publish_to_room(TellDragonStoryEffect.new(dragon, s)) if s && (s.length > 0)
    else
      falling_loc = world.find_singleton("mangrove/Falling/default")
      victims.each { |v| v.move_to(falling_loc) }
      falling_loc.time_of_falling = time
      dragon.move_to(lair_loc)
      # TODO - move all contents of this room to somewhere else.
      lair_loc.publish_to_room(TellDragonStoryEffect.new(dragon, "A massive green dragon descends from the sky! The earth shakes as it lands!"))
    end
  end

  def after_properties_set
    verb(["help"]) { |response, command, match|
      response.message = @responses.sample
      response.handled = true
    }
    alias_verb(["east"], ["help"])
    alias_verb(["north"], ["help"])
    alias_verb(["south"], ["help"])
    alias_verb(["west"], ["help"])
    alias_verb(["up"], ["help"])
    alias_verb(["down"], ["help"])
    alias_verb(["in"], ["help"])
    alias_verb(["out"], ["help"])
    alias_verb(["escape"], ["help"])
    alias_verb(["scream"], ["help"])
    alias_verb(["struggle"], ["help"])
  end
end


class DragonLair < Outdoor
  def dragon_available?
    dragon = world.find_singleton(DRAGON)
    return false unless dragon && dragon.location == self
    contents.each { |c|
      return false if (c.is_a? Body) && c != dragon
    }
    true
  end
end

class GreenDragon < SingletonCreature

end

class Falling < Outdoor
  attr_writer :time_of_falling

  def heartbeat(time, time_of_day)
    swamp_loc = world.find_singleton("mangrove/Outdoor/scaryswamp1")
    unless @time_of_falling
      @contents.each { |c| c.move_to(swamp_loc) }
      return
    end
    return unless @time_of_falling
    victims = contents.select { |c| c.is_a? Body }
    if victims.length == 0
      @time_of_falling = 0
      return
    end
    i = time - @time_of_falling
    if i < @story.length
      s = @story[i]&.strip
      publish_to_room(TellDragonStoryEffect.new(nil, s)) if s && (s.length > 0)
    else
      victims = contents.select { |c| c.is_a? Body }
      victims.each { |victim|
        dest = @destinations.keys.sample
        transition = @destinations[dest]['transition']
        dest = world.dest(wizard,dest)
        victim.tell(transition) if transition
        victim.move_to_location(dest)
      }
    end
  end
end
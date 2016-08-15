require_relative '../lib/room'
require_relative '../../src/shared/effects'

DAWN_TIMES = [0, 10, 20, 30]
DUSK_TIMES = [300, 310, 320, 330]

class Outdoor < Room
  def heartbeat(time, time_of_day)
    if DAWN_TIMES.include? time_of_day
      publish_to_room(TimeOfDayEffect.new("The sun is coming up."))
    elsif DUSK_TIMES.include? time_of_day
      publish_to_room(TimeOfDayEffect.new("The sun is going down."))
    end
  end

  def lit?
    super || (world.time_of_day < 340)
  end
end

class Gong < Item
  # TODO define verb
  def carriable?
    false
  end
end

class Undead < Creature

end

class NecklaceOfRegeneration < Wearable
  def heartbeat(t1, t2)
    if @location.instance_of? Body
      if @location.wearing?(self)
        if @location.instance_of? Undead
          @location.damage(1)
        else
          @location.heal(1)
        end
      end
    end
  end
end

class ThothTemple < Room
  def receive_into_container(thing)
    super
    if thing.ghost?
      thing.tell("It is time for you to enter the Book of the Dead.")
    end
  end
end

class EnterBookEffect < Effect
  def initialize(actor)
    @actor = actor
  end

  def message_for(observer)
    if observer == @actor
      Observation.new("You approach the Book of Dead and are sucked into the pages! Your story is added to the book.")
    else
      Observation.new("#{@actor.short} approaches the Book of Dead and is sucked into the pages!")
    end
  end
end

class BookOfTheDead < Virtual
  def after_properties_set
    verb(["enter", :it]) { |response,command,match|
      if command.body.ghost?
        command.room.publish_to_room(EnterBookEffect.new(command.body))
        command.body.move_to_location("lib/Room/hall1")
      else
        response.message = "Only the dead may enter the book."
      end
      response.handled = true
    }
  end
end
require_relative '../lib/room.rb'
require_relative '../../src/shared/effects.rb'

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

  def lit?()
    world.time_of_day < 340
  end
end

class Weapon < Thing
  # TODO
end

class Gong < Thing
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
        elsif @location.injured
          @location.heal(1)
        end
      end
    end
  end
end
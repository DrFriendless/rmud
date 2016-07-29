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
        else
          @location.heal(1)
        end
      end
    end
  end
end



class Chest < Thing
  include Container

  def initialize()
    super
    initialize_contents
  end

  def persist(data)
    super
    persist_contents(data)
  end

  def restore(data, by_persistence_key)
    super
    restore_contents(data, by_persistence_key)
  end

  def after_properties_set()
    super
    if @openable
      verb(["open", :it]) { |response, command, match|
        # todo
        response.handled = true
      }
      verb(["close", :it]) { |response, command, match|
        # todo
        response.handled = true
      }
    end
    verb(["look", "inside", :it]) { |response, command, match|
      # todo
      response.handled = true
    }
    alias_verb(["look", "in", :it], ["look", "inside", :it])
    verb(["get", :plus, "from", :it]) { |response, command, match|
      # todo
      response.handled = true
    }
    verb(["put", :plus, "into", :it]) { |response, command, match|
      # todo
      response.handled = true
    }
    alias_verb(["put", :plus, "in", :it], ["put", :plus, "into", :it])
  end

  def weight()
    # todo
    super
  end
end
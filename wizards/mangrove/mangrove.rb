require_relative '../lib/lib.rb'
require_relative '../../src/shared/effects.rb'

DAWN_TIMES = [0, 10, 20, 30]
DUSK_TIMES = [300, 310, 320, 330]

class Outdoor < Room
  def publish_to_room(effect)
    @contents.each { |c| c.effect(effect) }
  end

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
    if @enter_it
      @enter_it = destination(@enter_it)
      verb(["enter", :it]) { |response, command, match|
        puts "body is #{command.body}"
        command.body.go_to(@enter_it)
        response.handled = true
      }
      alias_verb(["enter"], ["enter", :it])
    end
  end

  def short
    ()
  end

  def long
    ()
  end
end
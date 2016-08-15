require_relative './creatures'
require_relative './room'

THOTH = "lib/Thoth/default"

class Thoth < SingletonCreature
  def heartbeat(time, time_of_day)
    if location.is_a? GreatLibrary
      ghosts = location.contents.select { |x| x.ghost? }
      if ghosts.size > 0
        ghost = ghosts[0]
        ghost.reincarnate
        ghost.heal(1000000)
        location.publish_to_room(ReincarnateEffect.new(self, ghost))
        ghost.tell("You feel as if you have turned over a new leaf.")
      else
        location.publish_to_room(TellRoom.new(self, "You are overwhelmed by the smell of wet paper."))
        location.publish_to_room(LeaveEffect.new(self, "to a quieter place"))
        move_to_location("lib/Room/private")
      end
    end
  end
end

class ReincarnateEffect < Effect
  def initialize(actor, target)
    @actor = actor
    @actor2 = target
  end

  def message_for(observer)
    Observation.new("#{@actor.name} decrees 'Let #{@actor2.name} be granted a new papyrus upon which to write.' The ghost of #{@actor2.name} is reincarnated!")
  end
end

class GreatLibrary < Room
  def publish_to_room(effect)
    super
    if effect.is_a? ArriveEffect
      arriver = effect.actor
      return unless arriver.ghost?
      thoth = world.find_singleton(THOTH)
      if thoth.location != self
        thoth.move_to(self)
        super(TellRoom.new(thoth, "You are overwhelmed by the smell of new books."))
        super(ArriveEffect.new(thoth))
      end
    end
  end
end
require_relative '../lib/creatures'

class SwampPuff < Creature
  def you_died(killed_by)
    location.publish_to_room(SwampPuffDieEffect.new("The swamp puff explodes is a cloud of poisonous gas!"))
    location.contents.each { |c|
      if (c.is_a? Body) && (!c.is_a? SwampPuff)
        attack = weaponless_attacks[0]
        attack_on(attack, c)
      end
    }
  end
end

class SwampPuffDieEffect < Effect
  def initialize(message)
    @msg = message
  end

  def message_for(observer)
    Observation.new(@msg) unless observer.is_a? SwampPuff
  end
end

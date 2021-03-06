require_relative '../lib/creatures'

class SwampPuff < Creature
  def you_died(killed_by)
    destroy
    location.publish_to_room(SwampPuffDieEffect.new("The swamp puff explodes is a cloud of poisonous gas!"))
    location.contents.each { |c|
      if c.is_a? Body
        attack = Attack.new('#{attackee} is hit by a puff of poisonous gas.', {:poison => 2.d6 }, [:breath])
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

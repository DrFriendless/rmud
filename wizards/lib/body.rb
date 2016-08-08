require_relative '../../src/server/thingutil.rb'
require_relative '../../src/server/thing.rb'
require_relative '../../src/shared/effects.rb'
require_relative './money.rb'
require_relative './experience.rb'
require_relative './score.rb'
require_relative './items.rb'
require_relative './bodyutil.rb'

class Body < Thing
  include Container
  include HasGold
  include Wearing
  include HitPoints

  attr_accessor :victim

  def initialize
    super
    initialize_contents
    initialize_gold
    initialize_wearing
    initialize_hp
  end

  def after_properties_set
    super
    after_properties_set_hp
    receive_into_container(world.create("lib/LivingSoul/default"))
  end

  def persist(data)
    super
    persist_contents(data)
    data[persistence_key] ||= {}
    persist_hit_points(data[persistence_key])
    persist_gold(data)
    ws = {}
    @wear_slots.each_pair { |k,vs|
      ws[k] = vs.map { |v| if v; v.persistence_key; else; () end }
    }
    data[persistence_key][:ws] = ws
  end

  def restore(data, by_persistence_key)
    super
    restore_contents(data, by_persistence_key)
    restore_gold(data, by_persistence_key)
    restore_hit_points(data, by_persistence_key)
    restored_wearing = data[:ws]
    return unless restored_wearing
    @wear_slots.each_pair { |slot,spots|
      restored_slot = restored_wearing[slot]
      next unless restored_slot
      spots.each_index { |i|
        spots[i] = restored_slot[i] && by_persistence_key[restored_slot[i]]
        # just in case we are no longer holding whatever we're wearing
        if spots[i] && spots[i].location != self
          spots[i] = nil
        end
      }
    }
  end

  def go_to(location, direction)
    self.location.publish_to_room(LeaveEffect.new(self, direction))
    self.move_to_location(location)
    self.location.publish_to_room(ArriveEffect.new(self))
  end

  def carriable?
    false
  end

  def do(command)
    message = CommandMessage.new(command)
    message.body = self
    EventLoop::enqueue(CommandEvent.new(message, self))
  end

  # response from a do
  def reply(message)
    tell(message)
  end

  def weaponless_attacks
    [Attack.new("flailing fists", { :bludgeoning => 1.d4 }, [])]
  end

  def find_new_victim
    nil
  end

  def heartbeat(time, time_of_day)
    attacked = false
    if @victim
      weapon = wielded_weapon
      p "weapon #{weapon}"
      attacks = weapon&.create_attacks || weaponless_attacks
      p "attacks are #{attacks}"
      attacks.each { |attack|
        if @victim.location != location
          @victim = find_new_victim
          tell("You are no longer in combat.") unless @victim
        elsif @victim.dead?
          p "Victim is dead."
          @victim = find_new_victim
        end
        if @victim
          attacked = true
          p "attack is #{attack}"
          armours = @victim.armours
          armours.each { |a| a.mutate_attack(attack) }
          p "attack became #{attack}"
          attack.annotations.each { |anno| @victim.tell(anno) }
          dmg = attack.total_damage
          if dmg > 0
            p "total damage is #{dmg}"
            location.publish_to_room(DamageEffect.new(self, victim, dmg, attack.desc))
            killed = @victim.damage(dmg)
            if killed

            end
          else
            location.publish_to_room(MissEffect.new(self, victim, attack.desc))
          end
        end
      }
    end
    attacked
  end

  def armours
    contents.
        select { |c| c.is_a? Armour }.
        reject { |c| (c.is_a? CanBeWorn) && !wearing?(c) }
  end

  def attacked_by(other)
    # TODO - possibly change who I'm attacking.
    # TODO - other sorts of reactions
    @victim = other unless @victim
  end
end


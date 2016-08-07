require_relative '../../src/server/thingutil.rb'
require_relative '../../src/server/thing.rb'
require_relative '../../src/shared/effects.rb'
require_relative './money.rb'
require_relative './experience.rb'
require_relative './score.rb'
require_relative './items.rb'

# FIXME: items can't claim two spots of the same type, e.g. you can't have an item which is two rings.
module Wearing
  def initialize_wearing
    @wear_slots = {'necklace' => [nil], 'hat' => [nil], 'ring' => [nil, nil], 'amulet' => [nil],
                   'righthand' => [nil], 'lefthand' => [nil], 'shoes' => [nil]}
  end

  # can we put it on now?
  def space_to_wear?(slots)
    slots.all? { |s| @wear_slots[s]&.include?(nil) }
  end

  # can we put it on now?
  def wearing_in_slots(slots)
    result = []
    slots.each { |s|
      if @wear_slots[s]
        @wear_slots[s].each { |x| if x && !result.include?(x); result.push(x) end }
      end
    }
    result
  end

  # do we even have the slots for this
  def could_wear?(slots)
    slots.all? { |s| @wear_slots[s] && @wear_slots[s].size > 0 }
  end

  # put it on
  def wear(item)
    slots = item.slots
    slots.each { |s| i = @wear_slots[s].find_index(nil); @wear_slots[s][i] = item }
  end

  # take it off
  def remove(item)
    slots = item.slots
    slots.each { |s| i = @wear_slots[s].find_index(item); @wear_slots[s][i] = nil }
  end

  def wearing?(obj)
    return false unless obj.slots
    obj.slots.any? { |slot| @wear_slots[slot]&.include?(obj) }
  end

  def persist_wearing(data)
    # TODO
  end

  def wielded_weapon
    @wear_slots.each_value { |items| items.each { |x| if x.is_a?(Weapon) && wearing?(x); return x; end } }
    nil
  end
end

module HitPoints
  attr_accessor :hp
  attr_accessor :maxhp

  def initialize_hp
    @hp = 0
    @maxhp = 0
  end

  def after_properties_set_hp
    if !@maxhp || @maxhp <= 0
      @maxhp = 1
    end
    if !@hp || @hp <= 0
      @hp = @maxhp
    end
  end

  def injured?
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

  def persist_hit_points(data)
    data[:maxhp] = @maxhp
    data[:hp] = @hp
  end

  def restore_hit_points(data, by_persistence_key)
    @maxhp = data[:maxhp]
    @hp = data[:hp]
  end

  def dead?
    @hp <= 0
  end
end

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
            @victim.damage(dmg)
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

# A PlayerBody is special because it can appear and disappear as players log in and out.
class PlayerBody < Body
  include HasExperience
  include HasScore

  attr_accessor :name
  attr_accessor :effect_callback
  attr_writer :short
  attr_writer :long

  def initialize
    super
    @loc = "lib/Room/lostandfound"
  end

  def after_properties_set
    super
    receive_into_container(world.create("lib/PlayerSoul/default"))
  end

  def persistence_key
    "player/#{@name}"
  end

  def persist(data)
    super
    data[persistence_key][:name] = @name
  end

  def player_persistence_data()
    data = {}
    data[:body] = 'lib/PlayerBody/default'
    data[:loc] = @location.persistence_key
    data[:gp] = @gp
    data[:xp] = @xp
    data[:score] = @score
    data
  end

  def restore_player_persistence_data(data)
    p "Restoring #{name} => #{data}"
    @gp = (data && data[:gp]) || 0
    @xp = (data && data[:xp]) || 0
    @score = (data && data[:score]) || 0
    move_to_location((data && data[:loc]) || "lib/Room/hallofdoors")
  end

  def effect(effect)
    if @effect_callback
      e = effect.message_for(self)
      if e; @effect_callback.effect(e) end
    end
  end

  def tell(message)
    ob = Observation.new(message)
    @effect_callback.effect(ob)
  end

  def attacked_by(other)
    # let the player choose what to do.
  end
end


require_relative '../../src/server/thingutil.rb'
require_relative '../../src/server/thing.rb'
require_relative '../../src/shared/effects.rb'
require_relative './money.rb'
require_relative './experience.rb'

module Wearing
  def initialize_wearing
    @wear_slots = {'necklace' => [nil], 'hat' => [nil], 'ring' => [nil, nil],
                   'righthand' => [nil], 'lefthand' => [nil], 'shoes' => [nil]}
  end

  def wear_slots(slot)
    @wear_slots[slot] || []
  end

  def wearing?(obj)
    return false unless obj.slots
    obj.slots.each { |slot|
      if wear_slots(slot).include?(obj)
        return true
      end
    }
    false
  end

  def persist_wearing(data)

  end
end

module HitPoints
  attr_accessor :hp
  attr_accessor :maxhp

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
end

class Body < Thing
  include Container
  include EffectObserver
  include HasGold
  include Wearing
  include HitPoints

  attr_accessor :victim

  def initialize
    super
    initialize_contents
    initialize_gold
    initialize_wearing
  end

  def after_properties_set
    super
    receive(world.create("lib/LivingSoul/default"))
    verb(["kill", :someone]) { |response, command, match|
      victim = command.room.find(match[0].join(' '))
      if victim != command.body
        p "You kill #{victim.short}."
      end
      response.handled = true
    }
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
    ws = data[:ws]
    if ws
      @wear_slots.each_pair { |k,vs|
        ss = ws[k]
        puts "ss = #{ss}"
        vs.each_index { |i|
          if ss[i]
            vs[i] = by_persistence_key[ss[i]]
          end
        }
      }
    end
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
end

# A PlayerBody is special because it can appear and disappear as players log in and out.
class PlayerBody < Body
  include HasExperience

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
    receive(world.create("lib/PlayerSoul/default"))
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
    data
  end

  def restore_player_persistence_data(data)
    p "Restoring #{name} => #{data}"
    @gp = data[:gp]
    @xp = data[:xp]
    move_to_location(data[:loc] || "lib/Room/hallofdoors")
  end

  def tell(message)
    ob = Observation.new(message)
    @effect_callback.effect(ob)
  end
end


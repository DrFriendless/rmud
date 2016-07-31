require_relative '../../src/server/thingutil.rb'
require_relative '../../src/server/thing.rb'
require_relative '../../src/shared/effects.rb'
require_relative './money.rb'

class Body < Thing
  include Container
  include EffectObserver
  include HasGold

  attr_accessor :hp
  attr_accessor :maxhp

  def initialize
    super
    initialize_contents
    initialize_gold
    @wear_slots = {"necklace" => [()], "hat" => [()], "ring" => [(), ()],
                   "right hand" => [()], "left hand" => [()], "shoes" => [()]}
  end

  def after_properties_set
    super
    receive(world.create("lib/LivingSoul/default"))
  end

  def wear_slots(slot)
    @wear_slots[slot] || []
  end

  def wearing?(obj)
    wear_slots(obj.slot).include?(obj)
  end

  def injured()
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

  def persist(data)
    super
    persist_contents(data)
    data[persistence_key] ||= {}
    data[persistence_key][:maxhp] = @maxhp
    data[persistence_key][:hp] = @hp
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
    @maxhp = data[:maxhp]
    @hp = data[:hp]
    ws = data[:ws]
    if ws
      @wear_slots.each_pair { |k,vs|
        ss = ws[k]
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
  attr_accessor :name
  attr_accessor :loc
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
    if @location
      data[persistence_key][:loc] = @location.persistence_key
      data[persistence_key][:name] = @name
    end
  end

  def tell(message)
    ob = Observation.new(message)
    @effect_callback.effect(ob)
  end
end


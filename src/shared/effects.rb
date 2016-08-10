# things that happen that can be observed in a location

class Observation
  def initialize(msg)
    @message = msg
  end

  def method_missing(method, *args)
    false
  end

  def to_s
    @message
  end

  attr_accessor :message

  def to_json
    JSON.generate({'message' => @message})
  end
end

SILENCE = ()

class Effect
  def message_for(observer)
    Observation.new(@message)
  end
end

class TellRoom < Effect
  def initialize(actor, s)
    @actor = s
    @s = s
  end

  def message_for(observer)
    (observer != @actor) ? Observation.new(@s) : nil
  end
end

class TimeOfDayEffect < Effect
  def initialize(s)
    @message = s
  end
end

class ArriveEffect < Effect
  def initialize(arriver)
    @actor = arriver
  end

  def message_for(observer)
    if observer == @actor
      lines = [observer.location.long] +
          observer.location.contents.select { |c| c != @actor }.map { |c| c.short }.select(&:itself)
      Observation.new(lines.join("\n"))
    else
      Observation.new("#{@actor.name} arrives.")
    end
  end

  attr_reader :actor
end

class LeaveEffect < Effect
  def initialize(leaver, direction)
    @actor = leaver
    @direction = direction
  end

  def message_for(observer)
    if observer != @actor
      Observation.new("#{@actor.name} departs #{@direction}.")
    end
  end

  attr_reader :actor
  attr_reader :direction
end

class ActorItemEffect < Effect
  def initialize(actor, item)
    @actor = actor
    @item = item
  end

  attr_reader :actor
  attr_reader :item

  def message_for_actor
  end

  def message_for_others
  end

  def message_for(observer)
    if observer == @actor
      message_for_actor
    else
      message_for_others
    end
  end
end

class ActorItemItemEffect < Effect
  def initialize(actor, item1, item2)
    @actor = actor
    @item1 = item1
    @item2 = item2
  end

  attr_reader :actor
  attr_reader :item1
  attr_reader :item2

  def message_for_actor
  end

  def message_for_others
  end

  def message_for(observer)
    if observer == @actor
      message_for_actor
    else
      message_for_others
    end
  end
end

class ActorActorEffect < Effect
  def initialize(actor1, actor2, msg1, msg2, msg_other)
    @actor1 = actor1
    @actor2 = actor2
    @msg1 = msg1
    @msg2 = msg2
    @msg_other = msg_other
  end

  attr_reader :actor1
  attr_reader :actor2

  def message_for(observer)
    if observer == @actor1
      Observation.new(@msg1)
    elsif observer == @actor2
      Observation.new(@msg2)
    else
      Observation.new(@msg_other)
    end
  end
end

class TakeEffect < ActorItemEffect
  def message_for_others
    Observation.new("#{@actor.name} picks up #{@item.short}.")
  end
end

class DropEffect < ActorItemEffect
  def message_for_others
    Observation.new("#{@actor.name} drops a #{@item.short}.")
  end
end

class WearEffect < ActorItemEffect
  def message_for_others
    Observation.new("#{@actor.name} wears a #{@item.short}.")
  end
end

class RemoveEffect < ActorItemEffect
  def message_for_others
    Observation.new("#{@actor.name} removes a #{@item.short}.")
  end
end

class BuyEffect < ActorItemEffect
  def message_for_others
    Observation.new("#{@actor.name} buys a #{@item.short}.")
  end
end

class SellEffect < ActorItemEffect
  def message_for_others
    Observation.new("#{@actor.name} sells a #{@item.short}.")
  end
end

class TradeEffect < ActorItemItemEffect
  def message_for_others
    Observation.new("#{@actor.name} trades #{@item1.short} for #{@item2.short}.")
  end
end

class GetFromEffect < ActorItemItemEffect
  def message_for_others
    Observation.new("#{@actor.name} gets #{@item1.short} from #{@item2.short}.")
  end
end

class PutIntoEffect < ActorItemItemEffect
  def message_for_others
    Observation.new("#{@actor.name} puts #{@item1.short} into #{@item2.short}.")
  end
end

class OpenEffect < ActorItemEffect
  def message_for_others
    Observation.new("#{@actor.name} opens #{@item.short}.")
  end
end

class CloseEffect < ActorItemEffect
  def message_for_others
    Observation.new("#{@actor.name} closes #{@item.short}.")
  end
end

class SayEffect < Effect
  def initialize(actor, says)
    @actor = actor
    @says = says
  end

  attr_reader :actor
  attr_reader :says

  def message_for(observer)
    if observer != @actor
      Observation.new("#{@actor.name} says \"#{@says}\"")
    end
  end
end

class AttackEffect < ActorActorEffect
  def initialize(attacker, attackee)
    super(attacker, attackee, nil, "#{attacker.name} attacks you!", "#{attacker.name} attacks #{attackee.name}!")
  end
end

class MissEffect < ActorActorEffect
  def initialize(attacker, attackee, attack_desc)
    super(attacker, attackee,
          "You miss #{attackee.name} with #{attack_desc}.",
          "#{attacker.name} misses you with #{attack_desc}.",
          "#{attacker.name} misses #{attackee.name} with #{attack_desc}.")
  end
end

class DamageEffect < ActorActorEffect
  def initialize(attacker, attackee, damage, attack_desc)
    @damage = damage
    s1 = case damage
           when 1..3; "You scratched #{attackee.name} with #{attack_desc}."
           when 4..8; "You injured #{attackee.name} with #{attack_desc}."
           when 9..16; "You hurt #{attackee.name} badly with #{attack_desc}."
           else; "You hurt #{attackee.name} very badly with #{attack_desc}."
         end
    s2 = case damage
           when 1..3; "#{attacker.name} scratched you with #{attack_desc}."
           when 4..8; "#{attacker.name} injured you with #{attack_desc}."
           when 9..16; "#{attacker.name} hurt you badly with #{attack_desc}."
           else; "#{attacker.name} hurt you very badly with #{attack_desc}."
         end
    s3 = case damage
           when 1..3; "#{attacker.name} scratched #{attackee.name} with #{attack_desc}."
           when 4..8; "#{attacker.name} injured #{attackee.name} with #{attack_desc}."
           when 9..16; "#{attacker.name} hurt #{attackee.name} badly with #{attack_desc}."
           else; "#{attacker.name} hurt #{attackee.name} very badly with #{attack_desc}."
         end
    super(attacker, attackee, s1, s2, s3)
  end

  attr_reader :damage
end
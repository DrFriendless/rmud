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
    (observer != @actor) ? s : nil
  end
end

class TimeOfDayEffect < Effect
  def initialize(s)
    @message = s
  end
end

class ArriveEffect < Effect
  def initialize(arriver)
    @arriver = arriver
  end

  def message_for(observer)
    if observer == @arriver
      lines = [observer.location.long] +
          observer.location.contents.select { |c| c != @arriver }.map { |c| c.long }.select(&:itself)
      Observation.new(lines.join("\n"))
    else
      Observation.new("#{@arriver.name} arrives.")
    end
  end

  attr_reader :arriver
end

class LeaveEffect < Effect
  def initialize(leaver, direction)
    @leaver = leaver
    @direction = direction
  end

  def message_for(observer)
    if observer != @leaver
      Observation.new("#{@leaver.name} departs #{@direction}.")
    end
  end

  attr_reader :leaver
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
      @msg1
    elsif observer == @actor2
      @msg2
    else
      @msg_other
    end
  end
end

class TakeEffect < ActorItemEffect
  def message_for_others
    Observation.new("#{@actor.name} picks up #{@item.a_short}.")
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
    Observation.new("#{@actor.name} trades #{@item1.a_short} for #{@item2.a_short}.")
  end
end

class GetFromEffect < ActorItemItemEffect
  def message_for_others
    Observation.new("#{@actor.name} gets #{@item1.a_short} from #{@item2.a_short}.")
  end
end

class PutIntoEffect < ActorItemItemEffect
  def message_for_others
    Observation.new("#{@actor.name} puts #{@item1.a_short} into #{@item2.a_short}.")
  end
end

class OpenEffect < ActorItemEffect
  def message_for_others
    Observation.new("#{@actor.name} opens #{@item.a_short}.")
  end
end

class CloseEffect < ActorItemEffect
  def message_for_others
    Observation.new("#{@actor.name} closes #{@item.a_short}.")
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
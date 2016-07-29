# things that happen that can be observed in a location

class Observation
  def initialize(msg)
    @message = msg
  end

  def method_missing(method, *args)
    false
  end

  attr_accessor :message
end

SILENCE = ()

class Effect
  def message_for(observer)
    Observation.new(@message)
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
      Observation.new(observer.location.long)
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

class TakeEffect < Effect
  def initialize(taker, item)
    @taker = taker
    @item = item
  end

  def message_for(observer)
    if observer != @taker
      Observation.new("#{@taker.name} picks up a #{@item.short}.")
    end
  end

  attr_reader :taker
  attr_reader :item
end

class DropEffect < Effect
  def initialize(dropper, item)
    @dropper = dropper
    @item = item
  end

  def message_for(observer)
    if observer != @dropper
      Observation.new("#{@dropper.name} drops a #{@item.short}.")
    end
  end

  attr_reader :dropper
  attr_reader :item
end

class WearEffect < Effect
  def initialize(wearer, item)
    @wearer = wearer
    @item = item
  end

  def message_for(observer)
    if observer != @wearer
      Observation.new("#{@wearer.name} wears a #{@item.short}.")
    end
  end

  attr_reader :wearer
  attr_reader :item
end

class RemoveEffect < Effect
  def initialize(wearer, item)
    @wearer = wearer
    @item = item
  end

  def message_for(observer)
    if observer != @wearer
      Observation.new("#{@wearer.name} removes a #{@item.short}.")
    end
  end

  attr_reader :wearer
  attr_reader :item
end

class BuyEffect < Effect
  def initialize(buyer, item)
    @buyer = buyer
    @item = item
  end

  def message_for(observer)
    if observer != @buyer
      Observation.new("#{@buyer.name} buys a #{@item.short}.")
    end
  end

  attr_reader :buyer
  attr_reader :item
end

class SellEffect < Effect
  def initialize(seller, item)
    @seller = seller
    @item = item
  end

  def message_for(observer)
    if observer != @seller
      Observation.new("#{@seller.name} sells a #{@item.short}.")
    end
  end

  attr_reader :seller
  attr_reader :item
end

class TradeEffect < Effect
  def initialize(trader, item1, item2)
    @trader = trader
    @item1 = item1
    @item2 = item2
  end

  def message_for(observer)
    if observer != @trader
      Observation.new("#{@trader.name} trades a #{@item1.short} for a #{@item2.short}.")
    end
  end
end

class ActorItemEffect < Effect
  def initialize(actor, item)
    @actor = actor
    @item = item
  end

  attr_reader :actor
  attr_reader :item
end

class OpenEffect < ActorItemEffect
  def message_for(observer)
    if observer != @actor
      Observation.new("#{@actor.name} opens #{@item.a_short}.")
    end
  end
end

class CloseEffect < ActorItemEffect
  def message_for(observer)
    if observer != @actor
      Observation.new("#{@actor.name} closes #{@item.a_short}.")
    end
  end
end

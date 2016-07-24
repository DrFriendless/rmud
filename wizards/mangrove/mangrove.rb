require_relative '../lib/room.rb'
require_relative '../../src/shared/effects.rb'

DAWN_TIMES = [0, 10, 20, 30]
DUSK_TIMES = [300, 310, 320, 330]

class Outdoor < Room
  def heartbeat(time, time_of_day)
    if DAWN_TIMES.include? time_of_day
      publish_to_room(TimeOfDayEffect.new("The sun is coming up."))
    elsif DUSK_TIMES.include? time_of_day
      publish_to_room(TimeOfDayEffect.new("The sun is going down."))
    end
  end

  def lit?()
    world.time_of_day < 340
  end
end

class Weapon < Thing
  # TODO
end

class Gong < Thing
  # TODO define verb
  def carriable?
    false
  end
end

class Undead < Creature

end

class NecklaceOfRegeneration < Wearable
  def heartbeat(t1, t2)
    if @location.instance_of? Body
      if @location.wearing?(self)
        if @location.instance_of? Undead
          @location.damage(1)
        else
          @location.heal(1)
        end
      end
    end
  end
end

class Shop < Room
  def after_properties_set()
    super
    @vault = destination(@vault)
    verb(["buy", :star]) { |response, command, match|
      item_name = match[0]
      if item_name.size == 0
        response.message = "Buy what?"
      end
      item = vault.find(item_name.join(' '))
      if item
        v = item.value * 3 / 2
        if command.body.pay_gold(v)
          response.message = "Done!"
          item.move_to(command.body)
          publish_to_room(BuyEffect.new(command.body, item))
        else
          response.message = "You haven't got enough money!"
        end
      else
        response.message = "We don't have any of those."
      end
      response.handled = true
    }
    verb(["sell", :star]) {  |response, command, match|
      item_name = match[0]
      if item_name.size == 0
        response.message = "Sell what?"
      end
      item = command.body.find(item_name.join(' '))
      if item
        if item.value <= 0
          response.message = "The shop doesn't want your rubbish."
        else
          if command.body.wearing?(item)
            command.body.do("remove #{item_name.join(' ')}")
          end
          if command.body.wearing?(item)
            response.message = "You can't remove the #{item.short}!"
          else
            v = item.value * 2 / 3
            command.body.gain_gold(v)
            item.move_to(vault)
            publish_to_room(SellEffect.new(command.body, item))
          end
        end
      else
        response.message = "You don't have any such thing."
      end
      response.handled = true
    }
    verb(["list"]) {  |response, command, match|
      items = vault.contents.map { |i|
        i.short + " (" + (i.value * 3/2).to_s + "gp)"
      }
      if items.size == 0
        items = ["Sorry, the shop has nothing for sale."]
      end
      response.message = items.join("\n")
      response.handled = true
    }
  end

  def vault()
    world.find_singleton(@vault)
  end
end
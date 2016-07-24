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
            response.message = "You got #{v} gold pieces."
            publish_to_room(SellEffect.new(command.body, item))
          end
        end
      else
        response.message = "You don't have any such thing."
      end
      response.handled = true
    }
    verb(["list"]) { |response, command, match|
      items = vault.contents.map { |i|
        i.short + " (" + (i.value * 3/2).to_s + "gp)"
      }
      if items.size == 0
        items = ["Sorry, the shop has nothing for sale."]
      end
      response.message = items.join("\n")
      response.handled = true
    }
    verb(["trade",:star,"for",:star]) { |response, command, match|
      response.handled = true
      if match.size != 2
        response.message = "You want to trade what for what?"
        return
      end
      name1 = match[0]
      name2 = match[1]
      if name1.size == 0
        response.message = "What are you offering?"
        return
      end
      if name2.size == 0
        response.message = "What is it you want?"
        return
      end
      their_item = command.body.find(name1.join(" "))
      shop_item = vault.find(name2.join(" "))
      if !their_item
        response.message = "You don't have a #{name1.join(' ')}."
        return
      end
      if !shop_item
        response.message = "We don't have a #{name2.join(' ')}."
        return
      end
      if their_item.value * 4/5 >= shop_item.value * 5/4
        if command.body.wearing?(their_item)
          command.body.do("remove #{name1.join(' ')}")
        end
        if command.body.wearing?(their_item)
          response.message = "You can't remove the #{their.short}!"
          return
        end
        their_item.move_to(vault)
        shop_item.move_to(command.body)
        response.message = "Done deal!"
        publish_to_room(TradeEffect.new(command.body, their_item, shop_item))
      else
        response.message = "No deal!"
      end
    }
  end

  def vault()
    world.find_singleton(@vault)
  end
end
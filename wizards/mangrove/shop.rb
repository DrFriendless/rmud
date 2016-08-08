require_relative '../lib/room'

class Shop < Room
  def after_properties_set()
    super
    @vault = local_dest(@vault)
    verb(["buy", :star]) { |response, command, match|
      item_name = match[0]
      if item_name.size == 0
        response.message = "Buy what?"
      end
      item = vault.find(item_name.join(' '))
      if item
        v = item.value * 3 / 2
        if command.body.pay(v)
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
    verb(["sell", :star]) { |response, command, match|
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
            response.message = "You can't sell the #{item.short} while you're wearing it!"
          else
            v = item.value * 2 / 3
            if v < 1; v = 1 end
            command.body.add_gold(v)
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
    verb(["trade",:plus,"for",:plus]) { |response, command, match|
      response.handled = true
      if match.size != 2
        response.message = "You want to trade what for what?"
        return
      end
      name1 = match[0]
      name2 = match[1]
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
          response.message = "You can't trade the #{their.short} while you're wearing it!"
          return
        end
        move_to_vault(their_item)
        shop_item.move_to(command.body)
        response.message = "Done deal!"
        publish_to_room(TradeEffect.new(command.body, their_item, shop_item))
      else
        response.message = "No deal!"
      end
    }
  end

  def move_to_vault(thing)
    # unload any containers sold to the shop
    if thing.instance_of? Container
      thing.contents.each { |t| move_to_vault(t) }
    end
    thing.move_to(vault)
  end

  def vault()
    world.find_singleton(@vault)
  end
end
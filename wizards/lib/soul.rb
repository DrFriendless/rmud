require_relative '../../src/server/thing'

class Soul < Thing
  def after_properties_set
    verb(["say", :star]) { |response, command, match|
      if command.say.length > 0
        command.room.publish_to_room(SayEffect.new(command.body, command.say))
      else
        response.message = "Say what?"
      end
      response.handled = true
    }
    verb(["kill", :someone]) { |response, command, match|
      victim = command.room.find(match[0].join(' '))
      if victim == command.body
        response.message = "You can't kill yourself."
      elsif !victim
        response.message = "Kill who?"
      else
        prev_victim = command.body.victim
        command.body.victim = victim
        if victim != prev_victim
          command.room.publish_to_room(AttackEffect.new(command.body, victim))
          victim.attacked_by(command.body)
        end
      end
      response.handled = true
    }
    alias_verb(["kill", :someone], ["attack", :someone])
    verb(["drop", :money]) { |response, command, match|
      quantity = parse_money(match[0].join(' '), command.body.gp)
      if quantity == 0
        command.body.tell("OK, you drop nothing.")
      elsif command.body.pay(quantity)
        obj = world.instantiate_gold(quantity)
        obj.move_to(command.body.location)
        command.room.publish_to_room(DropGoldEffect.new(command.body, quantity))
      end
      response.handled = true
    }
    verb(["emote", :plus]) { |response, command, match|
      does = match[0].join(' ')
      command.room.publish_to_room(EmoteEffect.new(command.body, does))
      response.handled = true
    }
  end

  def do_not_persist?
    true
  end
end

class LivingSoul < Soul

end
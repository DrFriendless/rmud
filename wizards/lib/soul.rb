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
  end

  def do_not_persist?
    true
  end
end

class LivingSoul < Soul

end
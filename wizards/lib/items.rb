require_relative '../../src/server/thing.rb'

class Wearable < Item
  def after_properties_set()
    verb(["wear", :it]) { |response, command, match|
      if command.body.wearing?(self)
        response.message = "You're already wearing it."
      elsif self.location != command.body
        response.message = "You don't have #{short}."
      else
        ws = command.body.wear_slots(@slot)
        if ws.include?(())
          pos = ws.index(())
          ws[pos] = self
          command.body.location.publish_to_room(WearEffect.new(command.body, self))
        elsif ws.size == 0
          response.message = "You could never wear that."
        else
          response.message = "You can't, you're already wearing #{ws[0].short}."
        end
      end
      response.handled = true
    }
    verb(["remove", :it]) { |response, command, match|
      if command.body.wearing?(self)
        ws = command.body.wear_slots(@slot)
        pos = ws.index(self)
        ws[pos] = ()
        command.body.location.publish_to_room(RemoveEffect.new(command.body, self))
      else
        response.message = "You're not wearing that."
      end
      response.handled = true
    }
  end

  attr_reader :slot
end
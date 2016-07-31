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
  end

  def do_not_persist?
    true
  end
end

class LivingSoul < Soul

end
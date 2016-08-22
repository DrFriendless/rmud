require_relative '../lib/room'

class AdvGuild < Room
  def after_properties_set
    super
    verb(["find", "quests"]) { |response, command, match|
      command.body.tell("Not implemented yet.")
      response.handled = true
    }
  end
end
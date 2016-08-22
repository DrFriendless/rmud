require_relative '../lib/virtual'
require_relative '../../src/shared/effects'

class Shrine < Virtual
  def after_properties_set
    super
    verb(["worship"])  { |response,command,match|
      if command.body.ghost?
        command.room.publish_to_room(ScriptedEffect.new(command.body, @effect_actor, @effect_observer))
        command.body.move_to_location("lib/Room/hall1")
      end
      response.handled = true
    }
    alias_verb(["pray", "to", "ra"], ["worship"])
    alias_verb(["worship", "ra"], ["worship"])
    alias_verb(["worship", "at", :it], ["worship"])
  end
end
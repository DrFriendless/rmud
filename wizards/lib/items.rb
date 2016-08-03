require_relative '../../src/server/thing.rb'

module CanBeWorn
  def after_properties_set_worn()
    verb([@wear_verb, :it]) { |response, command, match|
      if command.body.wearing?(self)
        response.message = "You're already #{@wearing_verb} it."
      elsif self.location != command.body
        response.message = "You don't have #{short}."
      elsif command.body.space_to_wear?(slots)
        command.body.wear(self)
        command.body.location.publish_to_room(WearEffect.new(command.body, self))
      elsif !command.body.could_wear?(slots)
        response.message = "You could never #{@wear_verb} that."
      else
        ws = command.body.wearing_in_slots(slots)
        response.message = "You can't, you're already #{@wearing_verb} #{ws[0].a_short}."
      end
      response.handled = true
    }
    verb([@unwear_verb, :it]) { |response, command, match|
      if command.body.wearing?(self)
        command.body.remove(self)
        command.body.location.publish_to_room(RemoveEffect.new(command.body, self))
      else
        response.message = "You're not #{@wearing_verb} that."
      end
      response.handled = true
    }
  end

  attr_accessor :worn_adjective
  attr_reader :slots
end

class Weapon < Item
  include CanBeWorn

  def initialize
    super
    @wear_verb = "wield"
    @wearing_verb = "wielding"
    @worn_adjective = "wielded"
    @unwear_verb = "unwield"
  end

  def after_properties_set
    super
    after_properties_set_worn
  end
end

class Wearable < Item
  include CanBeWorn

  def initialize
    super
    @wear_verb = "wear"
    @wearing_verb = "wearing"
    @worn_adjective = "worn"
    @unwear_verb = "remove"
  end

  def after_properties_set
    super
    after_properties_set_worn
  end
end
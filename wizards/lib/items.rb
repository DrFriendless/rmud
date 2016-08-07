require_relative '../../src/server/thing.rb'
require_relative './item.rb'

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
        response.message = "You can't, you're already #{ws.wearing_verb} #{ws[0].a_short}."
      end
      response.handled = true
    }
    alias_verb(["use", :it], [@wear_verb, :it])
    verb([@unwear_verb, :it]) { |response, command, match|
      if command.body.wearing?(self)
        command.body.remove(self)
        command.body.location.publish_to_room(RemoveEffect.new(command.body, self))
      else
        response.message = "You're not #{@wearing_verb} that."
      end
      response.handled = true
    }
    alias_verb(["stop", "using", :it], [@unwear_verb, :it])
  end

  attr_accessor :worn_adjective
  attr_reader :wearing_verb
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

  def create_attacks
    [Attack.new(@attack_description, {@damage_type.intern => eval(@damage)}, [:weapon])]
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

# The damage done by an attack. This is created by the weapon or spell and modified by the victim's armour.
# suggested damage types: :piercing :slashing :bludgeoning :fire :cold :electricity :acid :necrotic
# suggested flags: :missile :breath :weapon :touch :vampiric
class Attack
  def initialize(desc, damages, flags=[])
    @desc = desc
    @damages = damages
    @flags = flags
    # comments to the players about what happened
    @annotations = []
  end

  def to_s
    @damages.to_s
  end

  def decrease(type, armour, percent_decrease, max_decrease)
    dmg = @damages[type] || 0
    return if dmg == 0
    dec = percent_decrease * dmg / 100
    dec = dec > max_decrease ? max_decrease : dec
    return if dec == 0
    if dec > 0
      @damages[type] -= dec
      @annotations.push("Your #{armour.short} blocks the #{@desc}!") if armour.short
    end
  end

  def intercept(armour, blocked)
    if blocked
      @damages = {}
      @annotations.push("Your #{armour.short} prevents the #{@desc}!") if armour.short
    end
  end

  def total_damage
    @damages.values.inject(0, :+)
  end

  def vampiric?
    @flags.include?(:vampiric)
  end

  def flag?(f)
    @flags.include?(f)
  end

  attr_reader :annotations
  attr_reader :desc
end

module Armour
  def mutate_attack(attack)
    attack
  end
end

class Shield < Wearable
  include Armour

  def mutate_attack(attack)
    if attack.flag?(:weapon)
      attack.decrease(:piercing, self, eval(@piercing_decrease), eval(@piercing_max))
      attack.decrease(:slashing, self, eval(@slashing_decrease), eval(@slashing_max))
      attack.decrease(:bludgeoning, self, eval(@bludgeoning_decrease), eval(@bludgeoning_max))
    elsif attack.flag?(:missile)
      attack.decrease(:piercing, self, eval(@piercing_decrease), eval(@piercing_max))
    elsif attack.flag?(:touch)
      attack.intercept(self, 1.d100 <= eval(@intercept_percent))
    elsif attack.flag?(:breath)
      attack.decrease(:fire, self, eval(@breath_decrease), eval(@breath_max))
      attack.decrease(:cold, self, eval(@breath_decrease), eval(@breath_max))
      attack.decrease(:electricity, self, eval(@breath_decrease), eval(@breath_max))
      attack.decrease(:acid, self, eval(@breath_decrease), eval(@breath_max))
    end
  end
end
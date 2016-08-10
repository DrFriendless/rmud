# The damage done by an attack. This is created by the weapon or spell and modified by the victim's armour.
# suggested damage types: :piercing :slashing :bludgeoning :fire :cold :electricity :acid :necrotic :poison :holy :unholy
# suggested flags: :missile :breath :weapon :touch :vampiric
class Attack
  def initialize(shortdesc, longdesc, damages, flags=[])
    @desc = shortdesc
    @long = longdesc
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
    @damages[type] = [dmg-dec, 0].max
    if dec > 0
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
  attr_reader :long
end

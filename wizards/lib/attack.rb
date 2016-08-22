# The damage done by an attack. This is created by the weapon or spell and modified by the victim's armour.
# suggested damage types: :piercing :slashing :bludgeoning :fire :cold :electricity :acid :necrotic :poison :holy :unholy :poison
# suggested flags: :missile :breath :weapon :touch :vampiric
class Attack
  def initialize(description, damages, flags=[])
    5/0 unless description
    @description = description
    @poison = damages[:poison] || 0
    damages.delete(:poison)
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
      @annotations.push("#{armour.short} prevents #{dec} #{type} damage!") if armour.short
    end
  end

  def intercept(armour, blocked)
    if blocked
      @damages = {}
      @annotations.push("#{armour.short} prevents the attack!") if armour.short
    end
  end

  def total_damage
    @damages.values.inject(0, :+)
  end

  def vampiric?
    flag?(:vampiric)
  end

  def flag?(f)
    @flags && @flags.include?(f)
  end

  attr_reader :annotations
  attr_reader :description
  attr_reader :poison
end

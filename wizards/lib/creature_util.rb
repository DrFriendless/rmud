class ChatMatch
  def initialize(pattern, response)
    @pattern = pattern.downcase
    @response = response
  end

  def match(s)
    /#{@pattern}/ =~ s.downcase
  end

  attr_reader :response
end

class ReactionMatch
  def initialize(clazz, response)
    @clazz = clazz
    @response = response
  end

  def match(e)
    e.is_a? @clazz
  end

  attr_reader :response
end

class DamageResistance < Thing
  include Armour

  def mutate_attack(attack)
    attack.decrease(:piercing, self, en(@piercing), en(@piercing_max, 1000000)) if @piercing
    attack.decrease(:slashing, self, en(@slashing), en(@slashing_max, 1000000)) if @slashing
    attack.decrease(:bludgeoning, self, en(@bludgeoning), en(@bludgeoning_max, 1000000)) if @bludgeoning
    attack.decrease(:fire, self, en(@fire), en(@fire_max, 1000000)) if @fire
    attack.decrease(:cold, self, en(@cold), en(@cold_max, 1000000)) if @cold
    attack.decrease(:electricity, self, en(@electricity), en(@electricity_max, 1000000)) if @electricity
    attack.decrease(:acid, self, en(@acid), en(@acid_max, 1000000)) if @acid
    attack.decrease(:poison, self, en(@poison), en(@poison_max, 1000000)) if @poison
    attack.decrease(:necrotic, self, en(@necrotic), en(@necrotic_max, 1000000)) if @necrotic
    attack.decrease(:holy, self, en(@holy), en(@holy_max, 1000000)) if @holy
    attack.decrease(:unholy, self, en(@unholy), en(@unholy_max, 1000000)) if @unholy
  end

  def en(x, default=0)
    if x == nil
      default
    elsif x.is_a? String
      eval(x)
    else
      x
    end
  end
end

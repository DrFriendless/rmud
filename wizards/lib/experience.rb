module HasExperience
  def initialize_xp
    @combatxp = 0
    @questxp = 0
  end

  def add_combat_experience(n)
    @combatxp += n
  end

  def add_quest_experience(n)
    @questxp += n
  end

  attr_reader :combatxp
  attr_reader :questxp
end
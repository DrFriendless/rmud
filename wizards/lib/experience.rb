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

  def experience_status
    "You have #{@combatxp} combat XP and #{@questxp} quest XP, making #{experience} total XP."
  end

  def experience
    (@combatxp <= @questxp) ? @combatxp * 2 : @questxp * 2
  end

  attr_reader :combatxp
  attr_reader :questxp
end
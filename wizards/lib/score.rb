module HasScore
  def initialize_score
    @score = 0
  end

  def add_score(n)
    @score += n
  end

  attr_accessor :score
end
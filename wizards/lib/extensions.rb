class Fixnum
  def d4
    self.times.map { 1 + rand(4) }.inject(0, :+)
  end

  def d6
    self.times.map { 1 + rand(6) }.inject(0, :+)
  end

  def d8
    self.times.map { 1 + rand(8) }.inject(0, :+)
  end

  def d10
    self.times.map { 1 + rand(10) }.inject(0, :+)
  end

  def d12
    self.times.map { 1 + rand(12) }.inject(0, :+)
  end

  def d20
    self.times.map { 1 + rand(20) }.inject(0, :+)
  end

  def d100
    self.times.map { 1 + rand(100) }.inject(0, :+)
  end
end
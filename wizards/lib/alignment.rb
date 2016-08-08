module HasAlignment
  def initialize_alignment
    @alignment = 0
  end

  def modify_alignment(n)
    # TODO need something more interesting than this
    @alignment += n
  end

  attr_reader :alignment
end
class AnnonceDetailMapper
  attr_accessor :parse, :col_index

  def initialize(parse, col_index)
    @parse = parse
    @col_index = col_index
  end
end

module DictFiltrator
  def correct?(word)
    [3,4,5,6,7,10].include?(word.length)
  end

  def correct_number?(number)
    /^[1-9]{10}$/ =~ number
  end
end 
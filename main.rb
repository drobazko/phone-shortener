require 'benchmark'
require 'yaml'
require 'pg'

module DictFiltrator
  def correct?(word)
    (3..7).include?(word.length) || word.length == 10
  end
end 

class DictIndexator
  include DictFiltrator
  attr_accessor :indexed_dict

  def initialize
    @dict = filter_dict
    @indexed_dict = {}
  end

  def string_traverse(s, dict, i = 0)
    return [s] if i > s.length - 1

    if dict.class == String
      [ dict, { s[i] => string_traverse(s, {}, i + 1) } ]  
    elsif dict.class == Array && dict.last.class == Hash
      [ dict.first, string_traverse(s, dict.last, i) ]
    elsif dict.class == Array
      [ dict.first, { s[i] => string_traverse(s, {}, i + 1) } ]
    elsif dict.class == Hash && dict.key?(s[i])
      dict.merge({ s[i] => string_traverse(s, dict[s[i]], i + 1) })   
    elsif dict.class == Hash
      dict.merge({ s[i] => string_traverse(s, {}, i + 1) })
    end
  end

  def traverse
    @indexed_dict = @dict.inject({}){|memo, word| string_traverse(word, memo)};nil
  end

  def save(indexed_dict = 'indexed-dictionary.txt')
    File.open(indexed_dict, 'w') { |f| f.puts @indexed_dict.to_yaml }
  end
end

class DictLoader
  include DictFiltrator

  def initialize(source_dict = 'dictionary.txt')
    @dict = File
      .readlines(source_dict)
      .map{|w| w.strip }
      .select{|w| correct?(w)}
      # .map{|w| { w => w.split('').map{|l| PhoneNumberConverter::REVERSE_MAPPER[l]}.join }}

    @conn = PG.connect( dbname: 'grabber_development' )
  end

  def load_to_db
    @conn.exec('DELETE FROM dict')
    @dict.each{|v| @conn.exec( "INSERT INTO dict (word) VALUES('#{v}')" ) } 
  end

  def load_to_arr
    @dict
  end
end

class PhoneNumberConverter
  include DictFiltrator

  def initialize
    # @dict = DictLoader.new.load_to_arr.group_by(&:length)
    @dict = DictLoader.new.load_to_arr
    @conn = PG.connect( dbname: 'grabber_development' )
  end

  MAPPER = {
    '2' => %w[A B C],
    '3' => %w[D E F],
    '4' => %w[G H I],
    '5' => %w[J K L],
    '6' => %w[M N O],
    '7' => %w[P Q R S],
    '8' => %w[T U V],
    '9' => %w[W X Y Z]
  }

  REVERSE_MAPPER = {
    'A' => '2',
    'B' => '2',
    'C' => '2',
    'D' => '3',
    'E' => '3',
    'F' => '3',
    'G' => '4',
    'H' => '4',
    'I' => '4',
    'J' => '5',
    'K' => '5',
    'L' => '5',
    'M' => '6',
    'N' => '6',
    'O' => '6',
    'P' => '7',
    'Q' => '7',
    'R' => '7',
    'S' => '7',
    'T' => '8',
    'U' => '8',
    'V' => '8',
    'W' => '9',
    'X' => '9',
    'Y' => '9',
    'Z' => '9'
  }

  def parse(number, holder, word = '', i = 0)
    if correct?(word) 
      qwt = qwt_in_db(word)
      if qwt.zero? 
        holder << word
        word = ''
        return
      end
    end

    # holder << word if  #and @dict[word.length].include?(word.upcase)
    return if i > number.length - 1
    MAPPER[number[i]].each{|l| parse(number, holder, word + l, i + 1)}
  end

  def qwt_in_db(word)
    @conn.exec("SELECT * FROM dict WHERE word like 'BABYS%'").getvalue(0,0).to_i
  end
end

holder = []
PhoneNumberConverter.new.parse('6686787825', holder)
puts holder

# DictLoader.new.load_to_db
# @conn = PG.connect( dbname: 'grabber_development' )
# @r = @conn.exec("SELECT COUNT(*) FROM dict WHERE word like 'AAH34%'")
# p @r.getvalue(0,0).to_i

# (1..5000).each{|v| @conn.exec("SELECT * FROM dict WHERE word like 'BABYS%'") }

# @dict = DictLoader.new.load_to_arr
# p @dict.last
# # 76126
# p @dict.count
# p @dict.group_by(&:length)

# p @dict.select{|d| d.length == 5}.count


# 3 3 4
# 4 3 3
# 3 4 3
# 5 5
# 4 6
# 6 4
# 3 7
# 7 3







# dict = DictIndexator.new
# puts dict.traverse
# puts dict.save

# PhoneNumberShortener.new

# conn = PG.connect( dbname: 'grabber_development' )
# conn.exec( "INSERT INTO dict (word) VALUES('first')" )

# @dict = File
#   .readlines('dictionary.txt')
#   .map{|d| d.strip }
#   .select{|d| ![1, 2, 8, 9].include?(d.length) && d.length <= 10}.count
# puts @dict 

# @dict = File
#   .readlines('dictionary.txt')
#   .map{|d| d.strip }
#   .select{|d| ![1, 2, 8, 9].include?(d.length) && d.length <= 10}
#   .each{|v| conn.exec( "INSERT INTO dict (word) VALUES('#{v}')" ) } 


# Benchmark.bm do |b|
#   dict = File.readlines('dictionary.txt')
#   b.report 'Normal method' do
#     dict.grep /UNSOUGHT/
#   end
# end


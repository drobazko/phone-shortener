require 'benchmark'
require 'yaml'

class DictIndexator
  attr_accessor :indexed_dict

  def initialize(source_dict = 'dictionary.txt')
    @indexed_dict = {}
    @dict = File
      .readlines(source_dict)
      .map{|d| d.strip }
      .select{|d| ![1, 2, 8, 9].include?(d.length) && d.length > 10}
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

class PhoneNumberShortener
  def initialize(dict = 'indexed-dictionary.txt')
    @dict = YAML.load_file(dict);nil
  end
end

# dict = DictIndexator.new
# puts dict.traverse
# puts dict.save

PhoneNumberShortener.new

# @dict = File
#   .readlines('dictionary.txt')
#   .map{|d| d.strip }
#   .select{|d| ![1, 2, 8, 9].include?(d.length) && d.length > 10}.count

# Benchmark.bm do |b|
#   dict = File.readlines('dictionary.txt')
#   b.report 'Normal method' do
#     dict.grep /UNSOUGHT/
#   end
# end


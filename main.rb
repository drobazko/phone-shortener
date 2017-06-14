require 'benchmark'
require 'yaml'
require 'pg'
require 'deepmap'
require 'redis'

module DictFiltrator
  def correct?(word)
    (3..7).include?(word.length) || word.length == 10
  end

  def correct_number?(number)
    /^[1-9]{10}$/ =~ number
  end
end 

module Persistance
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
      .map{|w| w.strip}
      .select{|w| correct? w }

    @conn = PG.connect( dbname: 'grabber_development' )
    @redis = Redis.new
    @converter = PhoneNumberConverter.new
  end

  def load_to_db
    @conn.exec('DELETE FROM dict')
    @dict.each{|v| @conn.exec( "INSERT INTO dict (word) VALUES('#{v}')" ) } 
  end

  def load_to_redis
    @dict.each{|word|
      if @redis.get(@converter.word_to_digits(word))
        @redis.set(@converter.word_to_digits(word), @redis.get(@converter.word_to_digits(word)) + '|' + word)
        next
      end

      @redis.set(@converter.word_to_digits(word), word)
    }
  end

  def load_to_arr
    @dict
  end
end

class PhoneNumberConverter
  include DictFiltrator

  NUMBER_SPLITTER = [
    '(\d{3})(\d{3})(\d{4})',
    '(\d{4})(\d{3})(\d{3})',
    '(\d{3})(\d{4})(\d{3})',
    '(\d{6})(\d{4})',
    '(\d{4})(\d{6})',
    '(\d{7})(\d{3})',
    '(\d{3})(\d{7})',  
    '(\d{5})(\d{5})',
    '(\d{10})'
  ]

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

  def initialize
    @conn = PG.connect( dbname: 'grabber_development' )
    @redis = Redis.new
  end

  def word_to_digits(word)
    word.split('').map{|c| REVERSE_MAPPER[c]}.join
  end

  def find_variants(phone_number = '6686787825', type = :redis)
    raise 'Phone number not allowed' unless correct_number?(phone_number)
    send("find_variants_#{type}", phone_number)
      .flat_map{ |v| v[0].product(*v[1..-1]) }
      .map{|v| v.count == 1 ? v[0] : v}
      .deep_map{|v| v.downcase}
  end

  private

  def find_variants_pg(phone_number)
    NUMBER_SPLITTER
      .map{ |pattern| phone_number.scan(/#{pattern}/).first }
      .map { |numbers|
        numbers.map do |number|
          holder = []
          parse(number, holder)
          { number => select_words_from_db(holder).column_values(0) }
        end
      }
      .map{ |v| v.flat_map(&:values) }
  end

  def find_variants_redis(phone_number)
    raise 'Phone number not allowed' unless correct_number?(phone_number)

    NUMBER_SPLITTER
      .map{ |pattern| phone_number.scan(/#{pattern}/).first }
      .map { |numbers|
        numbers.map{|n| next unless n; @redis.get(n).to_s.split('|')}
      }
  end

  def select_words_from_db(words)
    @conn.exec( "SELECT word FROM dict WHERE word in (#{words.map{|h| "'#{h}'"}.join(',')})" )
  end

  def parse(number, holder = [], word = '', i = 0)
    holder << word if correct?(word) && number.length == word.length
    return if i > number.length - 1
    MAPPER[number[i]].each{|l| parse(number, holder, word + l, i + 1)}
  end
end

phone = '6686787825'

# DictLoader.new.load_to_redis

Benchmark.bm do |b|
  b.report 'Converter' do
    # p PhoneNumberConverter.new.find_variants(phone, :pg)
    p PhoneNumberConverter.new.find_variants(phone, :redis)
  end
end
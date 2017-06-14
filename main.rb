require 'benchmark'
require 'yaml'
require 'pg'
require 'deepmap'
require 'redis'

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

phone = '2282668687'

# DictLoader.new.load_to_redis

Benchmark.bm do |b|
  b.report 'Converter' do
    p PhoneNumberConverter.new.find_variants(phone, :pg)
    p PhoneNumberConverter.new.find_variants(phone, :redis)
  end
end
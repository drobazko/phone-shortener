require_relative 'dict_filtrator'
require_relative '../phone_number_converter'

class DictLoader
  include DictFiltrator

  def initialize(client, source_dict = '../data/dictionary.txt')
    @dict = File
      .readlines(source_dict)
      .map{|w| w.strip}
      .select{|w| correct? w }

    @client = client
    @converter = PhoneNumberConverter.new
  end

  def load_to_db
    @client.exec('DELETE FROM dict')
    @dict.each{|v| @client.exec( "INSERT INTO dict (word) VALUES('#{v}')" ) } 
  end

  def load_to_redis
    @dict.each{|word|
      digits = @converter.word_to_digits(word)
      if @redis.get(digits)
        @redis.set(digits, @redis.get(digits) + '|' + word)
        next
      end

      @redis.set(digits, word)
    }
  end

  def load_to_arr
    @dict
  end
end
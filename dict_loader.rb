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

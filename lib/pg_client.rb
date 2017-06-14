require 'pg'

class PgClient
  TYPE = :pg

  def connect 
    @client = PG.connect( dbname: 'grabber_development' )
  end

  def find_words(words)
    @client ||= connect
    @client.exec( "SELECT word FROM dict WHERE word in (#{words.map{|h| "'#{h}'"}.join(',')})" )
  end
end
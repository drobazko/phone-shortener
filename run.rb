require 'benchmark'
require_relative 'lib/pg_client'
require_relative 'lib/redis_client'
require_relative 'phone_number_converter'

Benchmark.bm do |b|
  b.report 'Pg persistence' do
    PhoneNumberConverter.new(PgClient.new).find_variants
  end
  b.report 'Redis persistence' do
    PhoneNumberConverter.new(RedisClient.new).find_variants
  end
end


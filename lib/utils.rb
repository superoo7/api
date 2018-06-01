def formatted_number(number, precision = 2)
  number.round(precision).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

def formatted_date(date)
  date.strftime("%e %b %Y")
end

def with_retry(limit)
  limit.times do |i|
    begin
      res = yield i
      if res.try(:error)
        puts res.error
        raise "#{res.error}"
      end

      return res
    rescue => e
      puts e
      raise e if i + 1 == limit
    end
    sleep(10)
  end
end
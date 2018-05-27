def formatted_number(number, precision = 2)
  number.round(precision).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

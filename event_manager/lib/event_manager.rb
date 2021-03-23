
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_numbers(num)
  good_num = num.gsub(/\D/, '')
  return good_num if good_num.length == 10
  return good_num[1..-1] if (good_num.length == 11 && good_num[0] == '1')
  return 'Invalid Number!'
end

def target(hsh)
  hash_days = hsh.reduce(Hash.new(0)) do |hash, val|
    hash[val] += 1
    hash
  end
  hash_days.key(hash_days.values.max)
end


def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

reg_hrs = []
reg_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  telephone_number = clean_numbers(row[:homephone])
  #puts telephone_number
  zipcode = clean_zipcode(row[:zipcode])

  reg_date_and_time = DateTime.strptime(row[:regdate], "%m/%d/%y %H:%M")

  reg_hrs << reg_date_and_time.hour
  reg_days << reg_date_and_time.strftime("%A")

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

puts "Hour of the day most people registered : ~#{target(reg_hrs)}:00"
puts "Day of the week most people registered : #{target(reg_days)}"
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
   if phone_number.length == 11 && phone_number[0] == "1" || phone_number.length==10
    phone_number[1..10].gsub!(/[^\d]/,'')
   else
     "Invalid Number"
   end
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

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

puts 'Event Manager Initialised!'

contents = CSV.open(
    'event_attendees.csv', 
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

registration_hours = Array.new
registration_days = Array.new
x = 0

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    
    phone_number = clean_phone_number(row[:homephone])
    
    reg_date_time = row[:regdate]

    date_time = DateTime.strptime(reg_date_time, "%m/%d/%y %H:%M")
    registration_hours[x] = date_time.hour
    registration_days[x] = date_time.wday
    x += 1

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
    end

puts "The most optimal advertising slot is the hour starting \
#{registration_hours.max_by{ |x| registration_hours.count(x)}}:00 on a \
#{Date::DAYNAMES[registration_days.max_by{ |y| registration_days.count(y)}]}"
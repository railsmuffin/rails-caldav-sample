def ics(name, uid:, start_time:)
  created = "#{time_in_format(Time.new.utc)}Z"
  tzid = 'Europe/Minsk'
  ['BEGIN:VCALENDAR',
   'VERSION:2.0',
   'PRODID:-//Apple Inc.//Mac OS X 10.10.3//EN',
   'CALSCALE:GREGORIAN',
   'BEGIN:VTIMEZONE',
   "TZID:#{tzid}",
   'BEGIN:DAYLIGHT',
   'TZOFFSETFROM:+0200',
   'RRULE:FREQ=YEARLY;UNTIL=20100328T000000Z;BYMONTH=3;BYDAY=-1SU',
   'DTSTART:19930328T020000',
   'TZNAME:GMT+3',
   'TZOFFSETTO:+0300',
   'END:DAYLIGHT',
   'BEGIN:STANDARD',
   'TZOFFSETFROM:+0200',
   'DTSTART:20110327T020000',
   'TZNAME:GMT+3',
   'TZOFFSETTO:+0300',
   'RDATE:20110327T020000',
   'END:STANDARD',
   'END:VTIMEZONE',
   'BEGIN:VEVENT',
   "CREATED:#{created}",
   "UID:#{uid}",
   "DTEND;TZID=#{tzid}:#{time_in_format((start_time + 1.hour).in_time_zone(tzid))}",
   'TRANSP:OPAQUE',
   "SUMMARY:#{name}",
   "DTSTART;TZID=#{tzid}:#{time_in_format(start_time.in_time_zone(tzid))}",
   "DTSTAMP:#{created}",
   'SEQUENCE:0',
   'END:VEVENT',
   'END:VCALENDAR',
   ''].join("\r\n")
end

def time_in_format(time)
  time.strftime('%Y%m%dT%H%M%S')
end

user = User.create!(email: 'caldav@example.com', password: 'password')

3.times do |n|
  calendar_name = "Calendar #{n + 1}"
  calendar = user.calendars.create!(name:        calendar_name,
                                    description: "Rails CalDav Sample application. #{calendar_name}.")

  [Time.zone.yesterday, Time.zone.today, Time.zone.tomorrow].each_with_index do |date, index|
    event_name = "Event #{index + 1} for #{calendar_name}"
    uid = SecureRandom.uuid.upcase
    ics_data = ics(event_name, uid: uid, start_time: date.to_time + (9 + n).hours)
    calendar.events.create!(uid: uid, ics: ics_data)
  end
end

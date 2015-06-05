class Caldav::CalendarResource < Caldav::BaseResource
  define_properties 'DAV:' do
    property 'resourcetype' do
      xml "<D:resourcetype><D:collection /><C:calendar xmlns:C='#{CALDAV_NS}'/></D:resourcetype>"
    end

    property 'resource-id' do
      calendar.id
    end

    property 'current-user-privilege-set' do
      xml do
        privileges = %w(read write write-properties write-content read-acl read-current-user-privilege-set)
        s = '<D:current-user-privilege-set xmlns:D="DAV:">%s</D:current-user-privilege-set>'

        privileges_aggregate = privileges.inject('') do |ret, priv|
          ret << '<D:privilege><D:%s /></D:privilege>' % priv
        end

        s % privileges_aggregate
      end
    end

    property 'supported-report-set' do
      xml do
        reports = %w(calendar-multiget calendar-query)
        s = '<D:supported-report-set>%s</D:supported-report-set>'

        reports_aggregate = reports.inject('') do |ret, report|
          ret << "<D:report><C:%s xmlns:C='#{CALDAV_NS}'/></D:report>" % report
        end

        s % reports_aggregate
      end
    end

    property 'displayname' do
      calendar.name
    end

    property 'creationdate' do
      calendar.created_at.httpdate
    end

    property 'getcontenttype' do
      'text/calendar'
    end

    property 'getlastmodified' do
      calendar.updated_at.httpdate
    end
  end

  define_properties CALDAV_NS do
    property 'calendar-description' do
      calendar.description
    end

    property 'supported-calendar-component-set' do
      xml do
        '<C:supported-calendar-component-set xmlns:C="urn:ietf:params:xml:ns:caldav">' \
          '<C:comp name="VEVENT"/>' \
        '</C:supported-calendar-component-set>'
      end
    end
  end

  def calendar
    @calendar ||= @options[:_object_] || super
  end

  def exist?
    calendar.present?
  end

  def collection?
    true
  end

  def children
    calendar.events.map { |event| child(Caldav::EventResource, event) }
  end

  def get(request, response)
    raise NotFound unless exist?

    response.body = ''
    calendar.caldav_events.each do |event|
      response.body << event.ics
    end
    response['Content-Length'] = response.body.bytesize.to_s

    OK
  end

  def find_child(event_uid)
    event = calendar.events.find_by(uid: File.basename(event_uid))
    child(Caldav::EventResource, event) if event.present?
  end
end

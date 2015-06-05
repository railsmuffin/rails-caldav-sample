class Caldav::EventResource < Caldav::BaseResource
  define_properties 'DAV:' do
    property 'resourcetype' do
      xml "<D:resourcetype><C:calendar xmlns:C='#{CALDAV_NS}'/></D:resourcetype>"
    end

    property 'resource-id' do
      uid
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

    property 'creationdate' do
      event.created_at.httpdate
    end

    property 'getcontenttype' do
      content_type
    end

    property 'getlastmodified' do
      event.updated_at.httpdate
    end
  end

  define_properties CALDAV_NS do
    property 'calendar-data' do
      event.ics if exist?
    end
  end

  def event
    @event ||= @options[:_object_] || calendar.events.find_by(uid: path.to_s.split('/').last.split('.').first)
  end

  def exist?
    event.present?
  end

  def collection?
    false
  end

  def get(request, response)
    raise NotFound unless exist?
    response.body = event.ics

    OK
  end

  def put(request, response)
    event = calendar.events.find_or_initialize_by(calendar: calendar, uid: request_uid)
    Created if event.update(ics: request.body.read)
  end

  def delete
    event.destroy
    NoContent
  end

  def post(request, response)
    raise HTTPStatus::Forbidden
  end

  def etag
    @etag ||= last_modified.httpdate
  end

  def last_modified
    @last_modified ||= event.updated_at
  end

  def uid
    event.uid
  end

  def content_type
    'text/calendar'
  end

  def content_length
    event.try(:ics).to_s.size
  end

  def request_uid
    request.path.to_s.split('/').last.split('.').first
  end
end

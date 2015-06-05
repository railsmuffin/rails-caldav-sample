class Caldav::CalendarsResource < Caldav::BaseResource
  define_properties 'DAV:' do
    property 'resourcetype' do
      xml "<D:resourcetype><D:collection /></D:resourcetype>"
    end
  end

  def exist?
    true
  end

  def collection?
    true
  end

  def children
    user.calendars.map { |calendar| child(Caldav::CalendarResource, calendar) }
  end
end

Rails.application.routes.draw do
  CALDAV_ROOT_PATH = '/caldav'
  
  def match_caldav(path, resource:, as:)
    handler = DAV4Rack::Handler.new root:             CALDAV_ROOT_PATH,
                                    root_uri_path:    CALDAV_ROOT_PATH,
                                    resource_class:   resource,
                                    controller_class: Caldav::BaseController
    match "#{CALDAV_ROOT_PATH}#{path}", to: handler, as: as, via: :all
  end

  match_caldav '/', resource: Caldav::PrincipalResource, as: :caldav
  match_caldav '/calendars/', resource: Caldav::CalendarsResource, as: :caldav_calendars
  match_caldav '/calendars/:calendar_id/', resource: Caldav::CalendarResource, as: :caldav_calendar
  match_caldav '/calendars/:calendar_id/:event_uid', resource: Caldav::EventResource,
                                                     as:       :caldav_calendar_event
end

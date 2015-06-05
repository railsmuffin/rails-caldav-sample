class Caldav::PrincipalResource < Caldav::BaseResource
  def exist?
    path == '' || path == '/'
  end

  def collection?
    true
  end

  define_properties 'DAV:' do
    property 'alternate-URI-set' do
      xml '<D:alternate-URI-set xmlns:D="DAV:" />'
    end

    property 'group-membership' do
      xml '<D:group-membership xmlns:D="DAV:" />'
    end

    property 'group-membership-set' do
      xml '<D:group-membership-set xmlns:D="DAV:" />'
    end

    property 'principal-URL' do
      xml "<D:principal-URL xmlns:D='DAV:'><D:href>#{root_uri_path}</D:href></D:principal-URL>"
    end

    property 'current-user-principal' do
      xml do
        "<D:current-user-principal xmlns:D='DAV:'>" \
          "<D:href>#{root_uri_path}</D:href>" \
        "</D:current-user-principal>"
      end
    end

    property 'acl' do
      xml do
        "<D:acl xmlns:D='DAV:'>" \
          "<D:ace>" \
            "<D:principal><D:href>#{root_uri_path}</D:href></D:principal>" \
            "<D:protected/>" \
            "<D:grant>#{get_privileges_aggregate}</D:grant>" \
          "</D:ace>" \
        "</D:acl>"
      end
    end

    property 'acl-restrictions' do
      xml '<D:acl-restrictions xmlns:D="DAV:"><D:grant-only/><D:no-invert/></D:acl-restrictions>'
    end

    property 'resourcetype' do
      xml '<resourcetype><D:collection /><D:principal /></resourcetype>'
    end

    property 'displayname' do
      'User Principal Resource'
    end

    property 'creationdate' do
      user.created_at
    end

    property 'getlastmodified' do
      user.updated_at
    end
  end

  define_properties CALDAV_NS do
    property 'calendar-home-set' do
      xml do
        "<C:calendar-home-set xmlns:C='#{CALDAV_NS}'>" \
          "<D:href xmlns:D='DAV:'>#{calendars_collection_url}</D:href>" \
        '</C:calendar-home-set>'
      end
    end
  end

  private

  def calendars_collection_url
    File.join(root_uri_path, '/calendars/')
  end
end

class Caldav::BaseController < DAV4Rack::Controller
  def report
    unless resource.exist?
      return NotFound
    end

    report_name = request_document.try(:root).try(:name)

    if %w(calendar-multiget calendar-query).include?(report_name)
      send(report_name.underscore)
    elsif report_name.nil?
      xml_error(BadRequest) do |err|
        err.send 'empty-request'
      end
    else
      xml_error do |err|
        err.send 'supported-report'
      end
    end
  end

  def put
    resource.put(request, response)
  end

  def mkcalendar
    raise DAV4Rack::HTTPStatus::MethodNotAllowed
  end

  private

  def calendar_multiget
    xpath = "/#{xpath_element('calendar-multiget', :caldav)}/#{xpath_element('href')}"
    hrefs = request_document.xpath(xpath).map(&:text).compact

    if hrefs.empty?
      xml_error(BadRequest) do |err|
        err.send :'href-missing'
      end
    end

    multistatus do |xml|
      hrefs.each do |_href|
        xml['D'].response do
          xml['D'].href _href

          uid = File.split(URI.parse(_href).path).last.to_s.gsub(/\.ics\z/, '')
          cur_resource = resource.self?(_href) ? resource : resource.find_child(uid)

          if cur_resource.exist?
            propstats(xml, get_properties(cur_resource, get_request_props_hash('calendar-multiget', request_document)))
          else
            xml.status "#{http_version} #{NotFound.status_line}"
          end
        end
      end
    end
  end

  def calendar_query
    multistatus do |xml|
      resource.children.each do |event|
        xml['D'].response do
          xml['D'].href event.public_path
          propstats(xml, get_properties(event, get_request_props_hash('calendar-query', request_document)))
        end
      end
    end
  end

  def xpath_element(name, ns_uri=:dav)
    ns_uri = { dav: 'DAV:', caldav: Caldav::BaseResource::CALDAV_NS }[ns_uri]
    "*[local-name()='#{name}' and namespace-uri()='#{ns_uri}']"
  end

  def get_request_props_hash(root_element, request_document)
    xpath = "/#{xpath_element(root_element, :caldav)}/#{xpath_element('prop')}"
    request_document.xpath(xpath).children
      .find_all { |n| n.element? }
      .map{ |n| to_element_hash(n) }
  end

  def xml_error(http_error_code=Forbidden, &block)
    render_xml(:error) do |xml|
      block.yield(xml)
    end
    raise http_error_code
  end

  def propfind
    if resource.exist?
      if request_document.xpath("//#{ns}propfind/#{ns}allprop").empty?
        check = request_document.xpath("//#{ns}propfind")
        if check && !check.empty?
          items = request_document.xpath("//#{ns}propfind/#{ns}prop").children.find_all(&:element?)
          properties = items.map do |item|
            hsh = to_element_hash(item)
            bad_request = hsh.namespace.nil? &&
              !ns.empty? &&
              request_document.to_s.scan(%r{<#{item.name}[^>]+xmlns=""}).empty?
            raise ::BadRequest if bad_request

            hsh
          end

          properties.compact!
        else
          raise ::BadRequest
        end
      else
        properties = resource.properties
      end

      multistatus do |xml|
        find_resources.each do |resource|
          xml['D'].response do
            url = url_format(resource)
            url = "#{scheme}://#{host}:#{port}#{url}" if resource.propstat_relative_path.blank?

            xml['D'].href url
            propstats(xml['D'], get_properties(resource, properties.empty? ? resource.properties : properties))
          end
        end
      end
    else
      ::NotFound
    end
  end

  def propstats(xml, stats)
    return if stats.empty?

    stats.each do |status, props|
      xml['D'].propstat do
        xml['D'].prop do
          props.each do |element, value|
            defn = xml.doc.root.namespace_definitions.find { |ns_def| ns_def.href == element[:ns_href] }

            if defn.nil?
              if element[:ns_href] && !element[:ns_href].empty?
                _ns = "unknown#{rand(65536)}"
                xml.doc.root.add_namespace_definition(_ns, element[:ns_href])
              else
                _ns = nil
              end
            else
              _ns = element[:ns_href].nil? ? nil : defn.prefix
            end

            ns_xml = _ns.nil? ? xml : xml[_ns]

            if value.is_a?(::Nokogiri::XML::Node) || value.is_a?(::Nokogiri::XML::DocumentFragment)
              xml.__send__ :insert, value
            elsif value.is_a?(::Symbol)
              ns_xml.send(element[:name]) { ns_xml.send(value) }
            else
              ns_xml.send(element[:name], value) { |x| x.parent.namespace = nil if _ns.nil? }
            end

            xml['D']
          end
        end
        xml.status "#{http_version} #{status.status_line}"
      end
    end
  end
end


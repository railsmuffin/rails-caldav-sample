module Caldav
  class MethodMissingRedirector
    def initialize(*methods, &block)
      @methods = methods
      @block = block
    end

    def method_missing(name, *args, &block)
      if @methods.empty? || @methods.include?(name)
        @block.call(name, *args, &block)
      end
    end
  end

  class BaseResource < DAV4Rack::Resource
    CALDAV_NS = 'urn:ietf:params:xml:ns:caldav'
    PRIVILEGES = %w(read read-acl read-current-user-privilege-set)

    def self.define_properties(namespace, &block)
      obj = MethodMissingRedirector.new(:property) do |method_name, name, &block|
        if method_name == :property
          define_property(namespace, name.to_s, &block)
        else
          raise NoMethodError, method_name
        end
      end

      obj.instance_eval(&block)
    end

    def self.define_property(namespace, name, &block)
      _properties["#{namespace}*#{name}"] = block
    end

    def self.properties
      inherited = superclass.respond_to?(:properties) ? superclass.properties : {}
      inherited.merge(_properties)
    end

    def self._properties
      @properties ||= {}
    end

    def user_agent
      options[:env]['HTTP_USER_AGENT'].to_s rescue ''
    end

    def router_params
      env['router.params'] || {}
    end

    def setup
      @propstat_relative_path = true
      @root_xml_attributes = {
        'xmlns:C'      => CALDAV_NS,
        'xmlns:APPLE1' => 'http://calendarserver.org/ns/',
        'xmlns:APPLE2' => 'http://apple.com/ns/ical/',
        'xmlns:ME'     => 'http://me.com/_namespace/'
      }
      @response['DAV'] = '1, 2, calendar-access'
    end

    def self?(other_path)
      other_public_path = @public_path[-1] == '/' ? (@public_path + '/') : @public_path[0..-2]
      [@public_path, other_public_path].include?(other_path)
    end

    def get_property(element)
      name = element[:name]
      namespace = element[:ns_href]

      key = "#{namespace}*#{name}"

      handler = self.class.properties[key]
      if handler.present?
        instance_exec(element, &handler)
      else
        super
      end
    end

    def xml(value=nil)
      value = yield if block_given?
      Nokogiri::XML::DocumentFragment.parse(value)
    end

    define_properties 'DAV:' do
      property 'current-user-privilege-set' do
        xml do
          '<D:current-user-privilege-set xmlns:D="DAV:">' \
            "#{get_privileges_aggregate}" \
          '</D:current-user-privilege-set>'
        end
      end

      property 'group' do
        ''
      end

      property 'owner' do
        xml "<D:owner xmlns:D='DAV:'><D:href>#{root_uri_path}</D:href></D:owner>"
      end
    end

    def properties
      self.class.properties.keys.map do |key|
        ns, name = key.split('*')
        { name: name, ns_href: ns }
      end
    end

    def children
      []
    end

    private

    def env
      options[:env] || {}
    end

    def root_uri_path
      tmp = @options[:root_uri_path]
      tmp.respond_to?(:call) ? tmp.call(env) : tmp
    end

    def get_privileges_aggregate
      PRIVILEGES.inject('') { |ret, priv| ret << '<D:privilege><D:%s /></D:privilege>' % priv }
    end

    def child(child_class, child)
      new_public = add_slashes(public_path)
      new_path = add_slashes(path)

      child_uid = child.try(:uid) || child.id
      child_class.new(
        "#{new_public}#{child_uid}",
        "#{new_path}#{child_uid}",
        request,
        response,
        options.merge(_object_: child, _parent_: self, user: user)
      )
    end

    def calendar
      @calendar ||= user.calendars.find_by(id: path.to_s.split('/')[2])
    end

    private

    def add_slashes(str)
      "/#{str}/".squeeze('/')
    end

    def authenticate(email, password)
      # You should store encrypted password instead of this. It's better to use Devise gem.
      # But here is just an example
      self.user = User.find_by(email: email, password: password)
    end
  end
end

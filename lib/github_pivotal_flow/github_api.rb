module GithubPivotalFlow
  # Client for the GitHub v3 API.
  class GitHubAPI
    attr_reader :config, :oauth_app_url

    def initialize config, options
      @config = config
      @oauth_app_url = options.fetch(:app_url)
    end

    # Fake exception type for net/http exception handling.
    # Necessary because net/http may or may not be loaded at the time.
    module Exceptions
      def self.===(exception)
        exception.class.ancestors.map {|a| a.to_s }.include? 'Net::HTTPExceptions'
      end
    end

    def api_host host
      host = host.downcase
      'github.com' == host ? 'api.github.com' : host
    end

    def username_via_auth_dance host
      host = api_host(host)
      config.github_username(host) do
        if block_given?
          yield
        else
          res = get("https://%s/user" % host)
          res.error! unless res.success?
          config.github_username = res.data['login']
        end
      end
    end

    def repo_info project
      get "https://%s/repos/%s/%s" %
              [api_host(project.host), project.owner, project.name]
    end

    def repo_exists? project
      repo_info(project).success?
    end

    # Returns parsed data from the new pull request.
    def create_pullrequest options
      project = options.fetch(:project)
      params = {
          :base => options.fetch(:base),
          :head => options.fetch(:head)
      }

      if options[:issue]
        params[:issue] = options[:issue]
      else
        params[:title] = options[:title] if options[:title]
        params[:body]  = options[:body]  if options[:body]
      end

      res = post "https://%s/repos/%s/%s/pulls" %
                     [api_host(project.host), project.owner, project.name], params

      res.error! unless res.success?
      res.data
    end

    def statuses project, sha
      res = get "https://%s/repos/%s/%s/statuses/%s" %
                    [api_host(project.host), project.owner, project.name, sha]

      res.error! unless res.success?
      res.data
    end

    module HttpMethods
      # Decorator for Net::HTTPResponse
      module ResponseMethods
        def status() code.to_i end
        def data?() content_type =~ /\bjson\b/ end
        def data() @data ||= MultiJson.load(body) end
        def error_message?() data? and data['errors'] || data['message'] end
        def error_message() error_sentences || data['message'] end
        def success?() Net::HTTPSuccess === self end
        def error_sentences
          data['errors'].map do |err|
            case err['code']
            when 'custom'        then err['message']
            when 'missing_field'
              %(Missing field: "%s") % err['field']
            when 'invalid'
              %(Invalid value for "%s": "%s") % [ err['field'], err['value'] ]
            when 'unauthorized'
              %(Not allowed to change field "%s") % err['field']
            end
          end.compact if data['errors']
        end
      end

      def get url, &block
        perform_request url, :Get, &block
      end

      def post url, params = nil
        perform_request url, :Post do |req|
          if params
            req.body = MultiJson.dump params
            req['Content-Type'] = 'application/json;charset=utf-8'
          end
          yield req if block_given?
          req['Content-Length'] = byte_size req.body
        end
      end

      def byte_size str
        if    str.respond_to? :bytesize then str.bytesize
        elsif str.respond_to? :length   then str.length
        else  0
        end
      end

      def post_form url, params
        post(url) {|req| req.set_form_data params }
      end

      def perform_request url, type
        url = URI.parse url unless url.respond_to? :host

        require 'net/https'
        req = Net::HTTP.const_get(type).new request_uri(url)
        # TODO: better naming?
        http = configure_connection(req, url) do |host_url|
          create_connection host_url
        end

        req['User-Agent'] = "Github-pivotal-flow #{GithubPivotalFlow::VERSION}"
        apply_authentication(req, url)
        yield req if block_given?
        finalize_request(req, url)

        begin
          res = http.start { http.request(req) }
          res.extend ResponseMethods
          return res
        rescue SocketError => err
          raise Context::FatalError, "error with #{type.to_s.upcase} #{url} (#{err.message})"
        end
      end

      def request_uri url
        str = url.request_uri
        str = '/api/v3' << str if url.host != 'api.github.com' && url.host != 'gist.github.com'
        str
      end

      def configure_connection req, url
        if ENV['HUB_TEST_HOST']
          req['Host'] = url.host
          url = url.dup
          url.scheme = 'http'
          url.host, test_port = ENV['HUB_TEST_HOST'].split(':')
          url.port = test_port.to_i if test_port
        end
        yield url
      end

      def apply_authentication req, url
        user = url.user ? CGI.unescape(url.user) : config.github_username(url.host)
        pass = config.github_password(url.host, user)
        req.basic_auth user, pass
      end

      def finalize_request(req, url)
        if !req['Accept'] || req['Accept'] == '*/*'
          req['Accept'] = 'application/vnd.github.v3+json'
        end
      end

      def create_connection url
        use_ssl = 'https' == url.scheme

        proxy_args = []
        if proxy = config.proxy_uri(use_ssl)
          proxy_args << proxy.host << proxy.port
          if proxy.userinfo
            # proxy user + password
            proxy_args.concat proxy.userinfo.split(':', 2).map {|a| CGI.unescape a }
          end
        end

        http = Net::HTTP.new(url.host, url.port, *proxy_args)

        if http.use_ssl = use_ssl
          # FIXME: enable SSL peer verification!
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        return http
      end
    end

    module OAuth
      def apply_authentication req, url
        if req.path =~ %r{^(/api/v3)?/authorizations$}
          super
        else
          user = url.user ? CGI.unescape(url.user) : config.github_username(url.host)
          token = config.github_api_token(url.host, user) {
            obtain_oauth_token url.host, user
          }
          req['Authorization'] = "token #{token}"
        end
      end

      def obtain_oauth_token host, user, two_factor_code = nil
        auth_url = URI.parse("https://%s@%s/authorizations" % [CGI.escape(user), host])
        # dummy request to trigger a 2FA SMS since a HTTP GET won't do it
        post(auth_url) if !two_factor_code

        # first try to fetch existing authorization
        res = get(auth_url) do |req|
          req['X-GitHub-OTP'] = two_factor_code if two_factor_code
        end
        unless res.success?
          if !two_factor_code && res['X-GitHub-OTP'].to_s.include?('required')
            two_factor_code = config.ask_auth_code
            return obtain_oauth_token(host, user, two_factor_code)
          else
            res.error!
          end
        end

        if found = res.data.find {|auth| auth['app']['url'] == oauth_app_url }
          found['token']
        else
          # create a new authorization
          res = post auth_url,
                     :scopes => %w[repo], :note => 'github-pivotal-flow', :note_url => oauth_app_url do |req|
            req['X-GitHub-OTP'] = two_factor_code if two_factor_code
          end
          res.error! unless res.success?
          res.data['token']
        end
      end
    end

    include HttpMethods
    include OAuth
  end
end

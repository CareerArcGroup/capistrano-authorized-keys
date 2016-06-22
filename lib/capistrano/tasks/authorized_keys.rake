require "capistrano/dsl/authorized_keys_paths"
require "capistrano/authorized_keys/helpers"

include Capistrano::AuthorizedKeys::Helpers
include Capistrano::DSL::AuthorizedKeysPaths

AUTHORIZED_KEYS_ABORT_MESSAGE = "The following hosts have an invalid authorized keys file: %s".freeze

namespace :authorized_keys do
  desc "Setup remote authorized_keys file"
  task :setup do
    on roles(fetch(:authorized_keys_server_roles)) do
      unless authorized_keys_remote_exists?
        execute("touch #{authorized_keys_remote_path}")
        execute("chmod 600 #{authorized_keys_remote_path}")
      end
    end
  end

  desc "Update remote authorized_keys file with local authorized_keys"
  task :update do
    validate_authorized_keys!
    hosts_with_invalid_authorized_keys = []

    on roles(fetch(:authorized_keys_server_roles)) do
      begin
        validate_authorized_keys_remote!

        upload!(authorized_keys_io, authorized_keys_temporary_path)

        if authorized_keys_remote_contains_keys?
          start_line = authorized_keys_remote_header_line_numbers[0]
          end_line   = authorized_keys_remote_footer_line_numbers[0]

          execute("sed -i '#{start_line},#{end_line}d' #{authorized_keys_remote_path}")
        end

        execute("cat #{authorized_keys_temporary_path} >> #{authorized_keys_remote_path}")
        execute("rm #{authorized_keys_temporary_path}")
      rescue Capistrano::AuthorizedKeys::InvalidAuthorizedKeysRemoteFile => ex
        fatal(ex.message)
        hosts_with_invalid_authorized_keys.push(host.hostname)
      end
    end

    abort(AUTHORIZED_KEYS_ABORT_MESSAGE % hosts_with_invalid_authorized_keys.join(", ")) if hosts_with_invalid_authorized_keys.any?
  end

  before :update, :setup
  before "deploy:updating", "authorized_keys:update"
end

namespace :load do
  task :defaults do
    set :authorized_keys_path, "config/authorized_keys"
    set :authorized_keys_server_roles, [:all]
  end
end

require "capistrano/dsl/authorized_keys_paths"
require "capistrano/authorized_keys/helpers"

include Capistrano::AuthorizedKeys::Helpers
include Capistrano::DSL::AuthorizedKeysPaths

namespace :load do
  task :default do
    set :authorized_keys_path, "config/authorized_keys"
    set :authorized_keys_server_roles, [:all]
  end
end

namespace :authorized_keys do
  desc "Setup remote authorized_keys file"
  task :setup do
    on roles(fetch(:authorized_keys_server_roles)) do
      execute("echo > #{authorized_keys_remote_path}") unless authorized_keys_remote?
    end
  end

  desc "Update remote authorized_keys file with local authorized_keys"
  task :update do
    on roles(fetch(:authorized_keys_server_roles)) do
      validate_authorized_keys!
      validate_authorized_keys_remote!

      upload!(authorized_keys_io, authorized_keys_temporary_path)

      if authorized_keys_remote_contains_keys?
        start_line = authorized_keys_remote_header_line_numbers[0]
        end_line   = authorized_keys_remote_footer_line_numbers[0]

        execute("sed -i '#{start_line},#{end_line}d' #{authorized_keys_remote_path}")
      end

      execute("cat #{authorized_keys_temporary_path} >> #{authorized_keys_remote_path}")
      execute("rm #{authorized_keys_temporary_path}")
    end
  end

  before :update, :setup
end
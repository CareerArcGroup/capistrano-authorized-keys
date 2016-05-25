module Capistrano
  module DSL
    module AuthorizedKeysPaths
      def authorized_keys_path
        fetch(:authorized_keys_path)
      end

      def authorized_keys_remote_path
        "/home/#{deploy_user}/.ssh/authorized_keys"
      end

      def authorized_keys_temporary_path
        "#{authorized_keys_remote_path}.tmp"
      end
    end
  end
end
module Capistrano
  module AuthorizedKeys
    module Helpers
      HEADER = "# Begin Capistrano-Authorized-Keys generated keys for: %s".freeze
      FOOTER = "# End Capistrano-Authorized-Keys generated keys for: %s".freeze
      AUTHORIZED_KEYS_DOESNT_EXIST = "missing local authorized keys file: '%s'"
      AUTHORIZED_KEYS_REMOTE_INVALID = "invalid remote authorized keys file: '%s'"

      def deploy_user
        capture(:id, "-un")
      end

      def authorized_keys
        @authorized_keys ||= File.read(authorized_keys_path)
      end

      def authorized_keys_header
        HEADER % fetch(:application)
      end

      def authorized_keys_footer
        FOOTER % fetch(:application)
      end

      def authorized_keys_io
        StringIO.new("#{authorized_keys_header}\n\n#{authorized_keys}\n\n#{authorized_keys_footer}\n")
      end

      def authorized_keys_remote?
        test("[ -e #{authorized_keys_remote_path} ]")
      end

      def authorized_keys_remote_contains_keys?
        authorized_keys_remote_header_line_numbers.one? && authorized_keys_remote_footer_line_numbers.one?
      end

      def authorized_keys_remote_excludes_keys?
        authorized_keys_remote_header_line_numbers.empty? && authorized_keys_remote_footer_line_numbers.empty?
      end

      def validate_authorized_keys!
        raise(AUTHORIZED_KEYS_DOESNT_EXIST % authorized_keys_path) unless File.exists?(authorized_keys_path)
      end

      def validate_authorized_keys_remote!
        raise(AUTHORIZED_KEYS_REMOTE_INVALID % authorized_keys_remote_path) unless authorized_keys_remote_valid?
      end

      def authorized_keys_remote_header_line_numbers
        line_numbers_in_authorized_keys_remote(authorized_keys_header)
      end

      def authorized_keys_remote_footer_line_numbers
        line_numbers_in_authorized_keys_remote(authorized_keys_footer)
      end

      def line_numbers_in_authorized_keys_remote(pattern)
        capture("egrep -n \"#{pattern}\" #{authorized_keys_remote_path} | cut -f1 -d:", raise_on_non_zero_exit: false).scan(/\d+/).map(&:to_i)
      end

      def authorized_keys_remote_valid?
        authorized_keys_remote_contains_keys? || authorized_keys_remote_excludes_keys?
      end
    end
  end
end
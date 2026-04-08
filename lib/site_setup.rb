require "io/console"

module SiteSetup
  class << self
    def run
      if complete?
        $stdout.puts "Setup is already complete"
        output_description_guidance_if_needed
        return true
      end

      setup_author
      setup_blog

      if complete?
        $stdout.puts "Setup is now complete"
        output_description_guidance_if_needed
        true
      else
        $stdout.puts "Something went wrong. Setup still incomplete"
        false
      end
    rescue EOFError
      $stdout.puts "\nSetup canceled: input was closed before completion."
      false
    end

    def complete?
      Author.instance? && Blog.instance?
    end

    private
      def setup_author
        return if Author.instance?

        $stdout.puts "== Author setup =="

        loop do
          author = Author.new(prompt_author_attributes)

          if author.save
            $stdout.puts "Created author."
            return
          end

          output_errors(author)
        end
      end

      def setup_blog
        return if Blog.instance?

        $stdout.puts "\n== Blog setup =="

        loop do
          blog = Blog.new(prompt_blog_attributes)

          if blog.save
            $stdout.puts "Created blog."
            return
          end

          output_errors(blog)
        end
      end

      def prompt_author_attributes
        {
          first_name: prompt_required("First name"),
          last_name: prompt_required("Last name"),
          email_address: prompt_required("Email address"),
          password: prompt_required("Password", secret: true),
          password_confirmation: prompt_required("Confirm password", secret: true)
        }
      end

      def prompt_blog_attributes
        {
          title: prompt_required("Blog title"),
          subtitle: prompt_optional("Blog subtitle (optional)")
        }
      end

      def output_errors(record)
        $stdout.puts "Could not create #{record.class.name.downcase}:"

        record.errors.full_messages.each do |message|
          $stdout.puts "- #{message}"
        end

        $stdout.puts "Please try again."
      end

      def prompt_required(label, secret: false)
        loop do
          value = prompt(label, secret: secret)

          return value if value.present?

          $stdout.puts "#{label} is required."
        end
      end

      def prompt_optional(label)
        prompt(label)
      end

      def prompt(label, secret: false)
        $stdout.print "#{label}: "
        read_input(secret: secret).strip
      end

      def read_input(secret: false)
        value = secret ? read_secret_input : $stdin.gets
        raise EOFError if value.nil?

        value
      end

      def read_secret_input
        value = $stdin.noecho(&:gets)

        # Ensure cursor does not remain on the same line.
        $stdout.puts

        value
      end

      def output_description_guidance_if_needed
        return unless Blog.instance.description.blank?

        $stdout.puts "Next step: add your full blog description at /admin/blog/edit"
      end
  end
end

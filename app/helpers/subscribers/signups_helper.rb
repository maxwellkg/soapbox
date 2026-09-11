module Subscribers::SignupsHelper
  def signup_frame_id
    "signup-form"
  end

  def signup_errors_id
    "signup-errors"
  end

  def signup_email_field_options
    options = {
      placeholder: "your email address",
      required: true,
      autocomplete: "email"
    }

    options[:aria] = { describedby: signup_errors_id } if @signup.errors.any?

    options
  end
end

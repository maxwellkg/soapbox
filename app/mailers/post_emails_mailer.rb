class PostEmailsMailer < ApplicationMailer
  default from: "updates@soapbox.com"

  def post_email
    post_email = params[:post_email]
    @post = post_email.post
    @subscriber = post_email.subscription.subscriber

    mail(
      to: post_email.email_to,
      subject: post_email.email_subject,
      list_unsubscribe: subscriber_unsubscribe_url(@subscriber)
    )
  end
end

module Admin::Posts::SetPost
  extend ActiveSupport::Concern

  private
    def set_post
      @post = Post.find_by!(slug: params.expect(:slug))
    end
end

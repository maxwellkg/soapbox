require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "index displays published posts and signup form" do
    get root_url

    assert_response :success
    assert_select "title", blogs(:instance).title
    assert_select "h1", text: blogs(:instance).title
    assert_select "form[action='#{signups_path}']"
    assert_select "input[name='subscriber[email_address]']"

    Post.published.each do |post|
      assert_select "h2", text: post.title
    end
  end

  test "index does not display draft posts" do
    get root_url

    assert_select "h2", text: posts(:draft).title, count: 0
  end

  test "show displays a published post" do
    post = posts(:published)

    get post_url(post)

    assert_response :success
    assert_select "title", post.title
    assert_select "h1", text: post.title
    assert_select "a[href='#{root_path}']", text: "see all posts"
    assert_select "a[href='#{edit_admin_post_path(post)}']", text: "edit post", count: 0
    assert_includes response.body, post.content.body.to_s
  end

  test "show displays edit post action for authenticated author" do
    post = posts(:published)
    sign_in_as(authors(:one))

    get post_url(post)

    assert_response :success
    assert_select "a[href='#{edit_admin_post_path(post)}']", text: "edit post"
  end

  test "show does not find draft posts" do
    get post_url(posts(:draft))

    assert_response :not_found
  end

  test "show does not find unknown slug" do
    get post_url(slug: "a-nonexistent-post")

    assert_response :not_found
  end

  test "index serves atom feed" do
    get feed_url(format: :atom)

    assert_response :success
    assert_equal Blog.instance.as_atom_feed_xml, response.body
  end
end

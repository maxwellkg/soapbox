require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "index displays published posts and signup form" do
    get root_url

    assert_response :success
    assert_select "title", blogs(:instance).title
    assert_select "h1", text: blogs(:instance).title
    assert_select "form[action='#{signups_path}']"
    assert_select "input[name='subscriber[email_address]']"

    Post.ordered_for_display.limit(20).each do |post|
      assert_select "h2", text: post.title
    end

    assert_select "h2", count: 20
    assert_select ".pagination-page", text: "Page 1 of 2"
    assert_select "link[rel='icon'][href='/icon.png']"
    assert_select "a[href='#{admin_root_path}']", text: "go to admin", count: 0
  end

  test "index displays go to admin action for authenticated author" do
    sign_in_as(authors(:one))

    get root_url

    assert_response :success
    assert_select "a[href='#{admin_root_path}']", text: "go to admin"
  end

  test "index renders blog site image and uses it for the favicon when attached" do
    blog = blogs(:instance)
    attach_site_image(blog)

    get root_url

    assert_response :success
    assert_select ".blog-title-image img[alt='#{blog.title} site image']"
    assert_select "link[rel='icon'][href*='active_storage']"
    assert_select "link[rel='apple-touch-icon'][href*='active_storage']"
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
    assert_includes response.body, post.content.to_html
  end

  test "show renders highlighted code blocks" do
    post = posts(:published)
    post.update!(content: "```ruby\nputs 'hello'\n```")

    get post_url(post)

    assert_response :success
    assert_select "pre.highlight"
    assert_select "pre.highlight", text: /puts 'hello'/
    assert_no_match(/>\s*ruby\s*</, response.body)
    assert_match(/\.highlight/, response.body)
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

  test "index paginates search results" do
    Post.reindex_all!

    get root_url, params: { search: "pagination fixture" }

    assert_response :success
    assert_select "article.post-preview", count: 20
    assert_select "p", text: "21 matching posts"
    assert_select ".pagination-page", text: "Page 1 of 2"
    assert_select "span.pagination-link-disabled", text: "Previous"
    assert_select "a.pagination-link[href*='search=pagination+fixture'][href*='page=2']", text: "Next"

    get root_url, params: { search: "pagination fixture", page: 2 }

    assert_response :success
    assert_select "article.post-preview", count: 1
    assert_select ".pagination-page", text: "Page 2 of 2"
    assert_select "a.pagination-link[href*='search=pagination+fixture'][href*='page=1']", text: "Previous"
    assert_select "span.pagination-link-disabled", text: "Next"
  end
end

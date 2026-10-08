require "test_helper"

class ActionText::Markdown::UploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(authors(:instance))
  end

  test "attach a file" do
    assert_changes -> { ActiveStorage::Attachment.count }, 1 do
      post action_text_markdown_uploads_url, params: {
        record_gid: posts(:published).to_signed_global_id.to_s,
        attribute_name: "content",
        file: fixture_file_upload("site_image.png", "image/png")
      }, as: :xhr
    end

    assert_response :success
    assert JSON.parse(response.body)["fileUrl"].start_with?("/")
  end

  test "view attached file" do
    post action_text_markdown_uploads_url, params: {
      record_gid: posts(:published).to_signed_global_id.to_s,
      attribute_name: "content",
      file: fixture_file_upload("site_image.png", "image/png")
    }, as: :xhr

    attachment = ActiveStorage::Attachment.order(:created_at).last

    get action_text_markdown_upload_url(slug: attachment.slug)

    assert_response :redirect
    assert_match(/\/rails\/active_storage\/.*\/site_image\.png/, @response.redirect_url)

    follow_redirect!

    assert_response :success
    assert_equal "max-age=#{1.year.to_i}, public", response.headers["Cache-Control"]
  end

  test "local storage serves uploads from permanent URLs" do
    assert_predicate ActiveStorage::Blob.services.fetch(:local), :public?
  end
end

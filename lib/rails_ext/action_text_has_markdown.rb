module ActionText
  module HasMarkdown
    extend ActiveSupport::Concern

    class_methods do
      def has_markdown(name, strict_loading: strict_loading_by_default)
        name = name.to_sym

        define_method(name) do
          public_send(:"markdown_#{name}") || public_send(:"build_markdown_#{name}")
        end

        define_method(:"#{name}?") do
          public_send(:"markdown_#{name}").present?
        end

        define_method(:"#{name}=") do |content|
          public_send(name).content = content
        end

        has_one :"markdown_#{name}", -> { where(name: name) },
          class_name: "ActionText::Markdown", as: :record, inverse_of: :record, autosave: true, dependent: :destroy,
          strict_loading: strict_loading

        scope :"with_markdown_#{name}", -> { includes("markdown_#{name}") }
        scope :"with_markdown_#{name}_and_embeds", -> { includes("markdown_#{name}": { embeds_attachments: :blob }) }
      end
    end

    def safe_markdown_attribute(name)
      if self.class.reflect_on_association("markdown_#{name}")&.klass == ActionText::Markdown
        public_send(name)
      end
    end
  end
end

ActiveSupport.on_load :active_record do
  include ActionText::HasMarkdown
end

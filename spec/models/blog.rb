module Blog
  def self.auto_migrate!
    [ User, Site, Article, Draft, Commenter, Comment ].each { |m| m.auto_migrate! }
  end

  module Resource
    def self.included(model)
      model.class_eval <<-EOS, __FILE__, __LINE__
        include DataMapper::Resource

        def self.default_repository_name
          ADAPTER
        end

        property :id,         DM::Serial
        property :created_at, DateTime,   :nullable => false, :default => lambda { Time.now }
        property :updated_at, DateTime

        before :update, :set_updated_at

        private

        def set_updated_at
          self.updated_at = Time.now if dirty?
        end
      EOS
    end
  end

  module Content
    def self.included(model)
      model.class_eval <<-EOS, __FILE__, __LINE__
        include Resource

        property :title,   String, :nullable => false
        property :content, Text,   :nullable => false

        belongs_to :site
        belongs_to :author, :class_name => 'User', :child_key => [ :author_id ]
      EOS
    end
  end

  class Site
    include Resource

    property :name, String, :nullable => false, :unique => true, :unique_index => true

#    has n, :users,    :through => Resource  # TODO: uncomment once ManyToMany works with namespaced models
    has n, :articles
    has n, :drafts
  end

  class User
    include Resource

    # NOTE: a real application should always store salted passwords,
    # or better yet use an algorithm like BCrypt to hash the passwords
    # for storage

    property :username, String,                    :nullable => false, :unique => true, :unique_index => true
    property :password, String, :length => 60
    property :name,     String,                    :nullable => false
    property :email,    String, :length => 6..320

#    has n, :sites,    :through => Resource  # TODO: uncomment once ManyToMany works with namespaced models
    has n, :articles, :child_key => [ :author_id ]
    has n, :drafts,   :child_key => [ :author_id ]
  end

  class Draft
    include Content
  end

  class Article
    include Content

    property :published_at, DateTime

    has n, :comments

    def published?
      published_at != nil
    end

    def publish
      return if published?
      update_attributes :publish_at, Time.now
    end
  end

  class Commenter
    include Resource

    property :name,  String,                    :nullable => false
    property :email, String, :length => 6..255, :nullable => false, :unique => true, :unique_index => true
  end

  class Comment
    include Resource

    property :content,     Text,     :nullable => false
    property :approved_at, DateTime

    belongs_to :approved_by, :class_name => 'User', :child_key => [ :approved_by_id ]
    belongs_to :article
    belongs_to :commenter
    belongs_to :site,        :through => :article

    def approved?
      approved_at != nil
    end

    def approve(user)
      return if approved?
      update_attributes :approved_at => Time.now, :approved_by => user
    end
  end
end

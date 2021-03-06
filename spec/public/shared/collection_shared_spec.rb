share_examples_for 'A public Collection' do
  before do
    %w[ @model @article @other @original @articles @other_articles ].each do |ivar|
      raise "+#{ivar}+ should be defined in before block" unless instance_variable_get(ivar)
    end
  end

  [ :add, :<< ].each do |method|
    it { @articles.should respond_to(method) }

    describe "##{method}" do
      before do
        @resource = @model.new(:title => 'Title')
        @return = @articles.send(method, @resource)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      it 'should append one Resource to the Collection' do
        @articles.last.should be_equal(@resource)
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end
  end

  it { @articles.should respond_to(:all) }

  describe '#all' do
    describe 'with no arguments' do
      before do
        @copy = @articles.dup
        @return = @resources = @articles.all
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      it 'should be expected Resources' do
        @resources.should == [ @article ]
      end

      it 'should have the same query as original Collection' do
        @return.query.should be_equal(@articles.query)
      end

      it 'should scope the Collection' do
        @resources.reload.should == @copy.entries
      end
    end

    describe 'with a query' do
      before do
        @new = @articles.create(:content => 'New Article')
        # search for the first 10 articles, then take the first 5, and then finally take the
        # second article from the remainder
        @copy = @articles.dup
        @return = @articles.all(:limit => 10).all(:limit => 5).all(:limit => 1, :offset => 1)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return a new Collection' do
        @return.should_not be_equal(@articles)
      end

      it 'should return expected Resources' do
        @return.should == [ @new ]
      end

      it 'should have a different query than original Collection' do
        @return.query.should_not == @articles.query
      end

      it 'should scope the Collection' do
        @return.reload.should == @copy.entries.first(10).first(5)[1, 1]
      end
    end

    describe 'with a query using raw conditions' do
      before do
        @new = @articles.create(:content => 'New Article')
        @copy = @articles.dup
        @return = @articles.all(:conditions => [ 'content = ?', 'New Article' ])
      end

      it 'should return a Collection' do
        unless @adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter)
          @return.should be_kind_of(DataMapper::Collection)
        end
      end

      it 'should return a new Collection' do
        unless @adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter)
          @return.should_not be_equal(@articles)
        end
      end

      it 'should return expected Resources' do
        unless @adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter)
          @return.should == [ @new ]
        end
      end

      it 'should have a different query than original Collection' do
        unless @adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter)
          @return.query.should_not == @articles.query
        end
      end

      it 'should scope the Collection' do
        unless @adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter)
          @return.reload.should == @copy.entries.select { |a| a.content == 'New Article' }.first(1)
        end
      end
    end

    describe 'with a query that is out of range' do
      it 'should raise an exception' do
        lambda {
          @articles.all(:limit => 10).all(:offset => 10)
        }.should raise_error(RuntimeError, 'outside range')
      end
    end
  end

  it { @articles.should respond_to(:at) }

  describe '#at' do
    describe 'with positive offset' do
      before do
        @return = @resource = @articles.at(0)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @resource.should == @article
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end

      unless loaded
        it 'should not be a kicker' do
          @articles.should_not be_loaded
        end
      end
    end

    describe 'with positive offset', 'after prepending to the collection' do
      before do
        @return = @resource = @articles.unshift(@other).at(0)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @resource.should be_equal(@other)
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end

      unless loaded
        it 'should not be a kicker' do
          @articles.should_not be_loaded
        end
      end
    end

    describe 'with negative offset' do
      before do
        @return = @resource = @articles.at(-1)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @resource.should == @article
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end

      unless loaded
        it 'should not be a kicker' do
          @articles.should_not be_loaded
        end
      end
    end

    describe 'with negative offset', 'after appending to the collection' do
      before do
        @return = @resource = @articles.push(@other).at(-1)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @resource.should be_equal(@other)
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end

      unless loaded
        it 'should not be a kicker' do
          @articles.should_not be_loaded
        end
      end
    end
  end

  it { @articles.should respond_to(:clear) }

  describe '#clear' do
    before do
      @resources = @articles.entries
      @return = @articles.clear
    end

    it 'should return a Collection' do
      @return.should be_kind_of(DataMapper::Collection)
    end

    it 'should return self' do
      @return.should be_equal(@articles)
    end

    it 'should make the Collection empty' do
      @articles.should be_empty
    end

    it 'should orphan the Resources' do
      @resources.each { |r| r.collection.should_not be_equal(@articles) }
    end
  end

  [ :collect!, :map! ].each do |method|
    it { @articles.should respond_to(method) }

    describe "##{method}" do
      before do
        @resources = @articles.dup.entries
        @return = @articles.send(method) { |r| @model.new(:title => 'Title') }
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      it 'should update the Collection inline' do
        @articles.each { |r| r.attributes.only(:title).should == { :title => 'Title' } }
      end

      it 'should orphan each replaced Resource in the Collection' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end
    end
  end

  it { @articles.should respond_to(:concat) }

  describe '#concat' do
    before do
      @return = @articles.concat(@other_articles)
    end

    it 'should return a Collection' do
      @return.should be_kind_of(DataMapper::Collection)
    end

    it 'should return self' do
      @return.should be_equal(@articles)
    end

    it 'should concatenate the two collections' do
      @return.should == [ @article, @other ]
    end

    it 'should relate each Resource to the Collection' do
      @other_articles.each { |r| r.collection.should be_equal(@articles) }
    end
  end

  it { @articles.should respond_to(:create) }

  describe '#create' do
    before do
      @return = @resource = @articles.create(:content => 'Content')
    end

    it 'should return a Resource' do
      @return.should be_kind_of(DataMapper::Resource)
    end

    it 'should be a Resource with expected attributes' do
      @resource.attributes.only(:content).should == { :content => 'Content' }
    end

    it 'should be a saved Resource' do
      @resource.should_not be_new_record
    end

    it 'should append the Resource to the Collection' do
      @articles.last.should be_equal(@resource)
    end

    it 'should use the query conditions to set default values' do
      @resource.attributes.only(:title).should == { :title => 'Sample Article' }
    end

    it 'should not append a Resource if create fails' do
      pending 'TODO: not sure how to best spec this'
    end
  end

  it { @articles.should respond_to(:delete) }

  describe '#delete' do
    describe 'with a Resource within the Collection' do
      before do
        @return = @resource = @articles.delete(@article)
      end

      it 'should return a DataMapper::Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be the expected Resource' do
        @resource.should == @article
      end

      it 'should remove the Resource from the Collection' do
        @articles.should_not include(@resource)
      end

      it 'should orphan the Resource' do
        @resource.collection.should_not be_equal(@articles)
      end
    end

    describe 'with a Resource not within the Collection' do
      before do
        @return = @articles.delete(@other)
      end

      it 'should return nil' do
        @return.should be_nil
      end
    end
  end

  it { @articles.should respond_to(:delete_at) }

  describe '#delete_at' do
    describe 'with an offset within the Collection' do
      before do
        @return = @resource = @articles.delete_at(0)
      end

      it 'should return a DataMapper::Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be the expected Resource' do
        @resource.key.should == @article.key
      end

      it 'should remove the Resource from the Collection' do
        @articles.should_not include(@resource)
      end

      it 'should orphan the Resource' do
        @resource.collection.should_not be_equal(@articles)
      end
    end

    describe 'with an offset not within the Collection' do
      before do
        @return = @articles.delete_at(1)
      end

      it 'should return nil' do
        @return.should be_nil
      end
    end
  end

  it { @articles.should respond_to(:delete_if) }

  describe '#delete_if' do
    describe 'with a block that matches a Resource in the Collection' do
      before do
        @resources = @articles.dup.entries
        @return = @articles.delete_if { true }
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      it 'should remove the Resources from the Collection' do
        @resources.each { |r| @articles.should_not include(r) }
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end
    end

    describe 'with a block that does not match a Resource in the Collection' do
      before do
        @resources = @articles.dup.entries
        @return = @articles.delete_if { false }
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      it 'should not modify the Collection' do
        @articles.should == @resources
      end
    end
  end

  it { @articles.should respond_to(:destroy) }

  describe '#destroy' do
    before do
      @return = @articles.destroy
    end

    it 'should return true' do
      @return.should be_true
    end

    it 'should remove the Resources from the datasource' do
      @model.all(:title => 'Sample Article').should be_empty
    end

    it 'should clear the collection' do
      @articles.should be_empty
    end
  end

  it { @articles.should respond_to(:destroy!) }

  describe '#destroy!' do
    before do
      @return = @articles.destroy!
    end

    it 'should return true' do
      @return.should be_true
    end

    it 'should remove the Resources from the datasource' do
      @model.all(:title => 'Sample Article').should be_empty
    end

    it 'should clear the collection' do
      @articles.should be_empty
    end

    it 'should bypass validation' do
      pending 'TODO: not sure how to best spec this'
    end
  end

  it { @articles.should respond_to(:first) }

  describe '#first' do
    before do
      @copy = @articles.dup
    end

    describe 'with no arguments' do
      before do
        @return = @resource = @articles.first
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @resource.should == @article
      end

      it 'should be first Resource in the Collection' do
        @resource.should == @copy.entries.first
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end

    describe 'with no arguments', 'after prepending to the collection' do
      before do
        @return = @resource = @articles.unshift(@other).first
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @resource.should be_equal(@other)
      end

      it 'should be first Resource in the Collection' do
        @resource.should be_equal(@copy.entries.unshift(@other).first)
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end

    describe 'with empty query' do
      before do
        @return = @resource = @articles.first({})
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @resource.should == @article
      end

      it 'should be first Resource in the Collection' do
        @resource.should == @copy.entries.first
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end

    describe 'with empty query', 'after prepending to the collection' do
      before do
        @return = @resource = @articles.unshift(@other).first({})
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @resource.should be_equal(@other)
      end

      it 'should be first Resource in the Collection' do
        @resource.should be_equal(@copy.entries.unshift(@other).first)
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end

    describe 'with a query' do
      before do
        @return = @resource = @articles.first(:content => 'Sample')
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should should be the first Resource in the Collection matching the query' do
        @resource.should == @article
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end

    describe 'with limit specified' do
      before do
        @return = @resources = @articles.first(1)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should be the expected Collection' do
        @resources.should == [ @article ]
      end

      it 'should be the first N Resources in the Collection' do
        @resources.should == @copy.entries.first(1)
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end
    end

    describe 'with limit specified', 'after prepending to the collection' do
      before do
        @return = @resources = @articles.unshift(@other).first(1)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should be the expected Collection' do
        @resources.should == [ @other ]
      end

      it 'should be the first N Resources in the Collection' do
        @resources.should == @copy.entries.unshift(@other).first(1)
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end
    end

    describe 'with limit and query specified' do
      before do
        @return = @resources = @articles.first(1, :content => 'Sample')
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should be the first N Resources in the Collection matching the query' do
        @resources.should == [ @article ]
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end
    end
  end

  it { @articles.should respond_to(:first_or_create) }

  describe '#first_or_create' do
    describe 'with conditions that find an existing Resource' do
      before do
        @return = @resource = @articles.first_or_create(@article.attributes)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be expected Resource' do
        @resource.should == @article
      end

      it 'should be a saved Resource' do
        @resource.should_not be_new_record
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end

    describe 'with conditions that do not find an existing Resource' do
      before do
        @conditions = { :content => 'Unknown Content' }
        @attributes = {}
        @return = @resource = @articles.first_or_create(@conditions, @attributes)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be expected Resource' do
        @resource.attributes.only(:title, :content).should == { :title => 'Sample Article', :content => 'Unknown Content' }
      end

      it 'should be a saved Resource' do
        @resource.should_not be_new_record
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end
  end

  it { @articles.should respond_to(:first_or_new) }

  describe '#first_or_new' do
    describe 'with conditions that find an existing Resource' do
      before do
        @return = @resource = @articles.first_or_new(@article.attributes)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be expected Resource' do
        @resource.should == @article
      end

      it 'should be a saved Resource' do
        @resource.should_not be_new_record
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end

    describe 'with conditions that do not find an existing Resource' do
      before do
        @conditions = { :content => 'Unknown Content' }
        @attributes = {}
        @return = @resource = @articles.first_or_new(@conditions, @attributes)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be expected Resource' do
        @resource.attributes.only(:title, :content).should == { :title => 'Sample Article', :content => 'Unknown Content' }
      end

      it 'should not be a saved Resource' do
        @resource.should be_new_record
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end
  end

  it { @articles.should respond_to(:get) }

  describe '#get' do
    describe 'with a key to a Resource within the Collection' do
      before do
        @return = @resource = @articles.get(*@article.key)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be matching Resource in the Collection' do
        @resource.should == @article
      end
    end

    describe 'with a key to a Resource not within the Collection' do
      before do
        @return = @articles.get(*@other.key)
      end

      it 'should return nil' do
        @return.should be_nil
      end
    end

    describe 'with a key not typecast' do
      before do
        @return = @resource = @articles.get(*@article.key.map { |v| v.to_s })
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be matching Resource in the Collection' do
        @resource.should == @article
      end
    end

    describe 'with a key to a Resource within a Collection using a limit' do
      before do
        @articles = @articles.all(:limit => 1)
        @return = @resource = @articles.get(*@article.key)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be matching Resource in the Collection' do
        @resource.should == @article
      end
    end

    describe 'with a key to a Resource within a Collection using an offset' do
      before do
        @new = @articles.create(:content => 'New Article')
        @articles = @articles.all(:offset => 1, :limit => 1)
        @return = @resource = @articles.get(*@new.key)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be matching Resource in the Collection' do
        @resource.should == @new
      end
    end

    describe 'with a key that is nil' do
      before do
        @key    = nil
        @return = @resource = @articles.get(@key)
      end

      it 'should return nil' do
        @return.should be_nil
      end
    end

    describe 'with a key that is an empty String' do
      before do
        @key    = ''
        @return = @resource = @articles.get(@key)
      end

      it 'should return nil' do
        @return.should be_nil
      end
    end
  end

  it { @articles.should respond_to(:get!) }

  describe '#get!' do
    describe 'with a key to a Resource within the Collection' do
      before do
        @return = @resource = @articles.get!(*@article.key)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be matching Resource in the Collection' do
        @resource.should == @article
      end
    end

    describe 'with a key to a Resource not within the Collection' do
      it 'should raise an exception' do
        lambda {
          @articles.get!(99)
        }.should raise_error(DataMapper::ObjectNotFoundError, "Could not find #{@model} with key [99] in collection")
      end
    end

    describe 'with a key not typecast' do
      before do
        @return = @resource = @articles.get!(*@article.key.map { |v| v.to_s })
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be matching Resource in the Collection' do
        @resource.should == @article
      end
    end

    describe 'with a key to a Resource within a Collection using a limit' do
      before do
        @articles = @articles.all(:limit => 1)
        @return = @resource = @articles.get!(*@article.key)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be matching Resource in the Collection' do
        @resource.should == @article
      end
    end

    describe 'with a key to a Resource within a Collection using an offset' do
      before do
        @new = @articles.create(:content => 'New Article')
        @articles = @articles.all(:offset => 1, :limit => 1)
        @return = @resource = @articles.get!(*@new.key)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should be matching Resource in the Collection' do
        @resource.should == @new
      end
    end

    describe 'with a key that is nil' do
      before do
        @key = nil
      end

      it 'should raise an exception' do
        lambda {
          @articles.get!(nil)
        }.should raise_error(DataMapper::ObjectNotFoundError, "Could not find #{@model} with key [#{@key.inspect}] in collection")
      end
    end

    describe 'with a key that is an empty String' do
      before do
        @key = ''
      end

      it 'should raise an exception' do
        lambda {
          @articles.get!(@key)
        }.should raise_error(DataMapper::ObjectNotFoundError, "Could not find #{@model} with key [#{@key.inspect}] in collection")
      end
    end
  end

  it { @articles.should respond_to(:insert) }

  describe '#insert' do
    before do
      @resources = @other_articles
      @return = @articles.insert(0, *@resources)
    end

    it 'should return a Collection' do
      @return.should be_kind_of(DataMapper::Collection)
    end

    it 'should return self' do
      @return.should be_equal(@articles)
    end

    it 'should insert one or more Resources at a given offset' do
      @articles.should == @resources + [ @article ]
    end

    it 'should relate the Resources to the Collection' do
      @resources.each { |r| r.collection.should be_equal(@articles) }
    end
  end

  it { @articles.should respond_to(:inspect) }

  describe '#inspect' do

    before do
      @copy = @articles.dup
      @copy << @model.new(:title => 'Other Article')
      @return = @copy.inspect
    end

    it { @return.should match(/\A\[.*\]\z/) }

    it { @return.should match(/\bid=#{@article.id}\b/) }
    it { @return.should match(/\bid=nil\b/) }

    it { @return.should match(/\btitle=\"Sample Article\"\s/) }
    it { @return.should match(/\btitle=\"Other Article\"\s/) }

  end

  it { @articles.should respond_to(:last) }

  describe '#last' do
    before do
      @copy = @articles.dup
    end

    describe 'with no arguments' do
      before do
        @return = @resource = @articles.last
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @resource.should == @article
      end

      it 'should be last Resource in the Collection' do
        @resource.should == @copy.entries.last
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end

    describe 'with no arguments', 'after appending to the collection' do
      before do
        @return = @resource = @articles.push(@other).last
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @resource.should be_equal(@other)
      end

      it 'should be last Resource in the Collection' do
        @resource.should be_equal(@copy.entries.push(@other).last)
      end

      it 'should relate the Resource to the Collection' do
        @resource.collection.should be_equal(@articles)
      end
    end

    describe 'with a query' do
      before do
        @return = @resource = @articles.last(:content => 'Sample')
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should should be the last Resource in the Collection matching the query' do
        @resource.should == @article
      end

      it 'should relate the Resource to the Collection' do
        skip = [   ]
        pending_if 'TODO: fix', skip.include?(@articles.class) do
          @resource.collection.should be_equal(@articles)
        end
      end
    end

    describe 'with limit specified' do
      before do
        @return = @resources = @articles.last(1)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should be the expected Collection' do
        @resources.should == [ @article ]
      end

      it 'should be the last N Resources in the Collection' do
        @resources.should == @copy.entries.last(1)
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end
    end

    describe 'with limit specified', 'after appending to the collection' do
      before do
        @return = @resources = @articles.push(@other).last(1)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should be the expected Collection' do
        @resources.should == [ @other ]
      end

      it 'should be the last N Resources in the Collection' do
        @resources.should == @copy.entries.push(@other).last(1)
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end
    end

    describe 'with limit and query specified' do
      before do
        @return = @resources = @articles.last(1, :content => 'Sample')
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should be the last N Resources in the Collection matching the query' do
        @resources.should == [ @article ]
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end
    end
  end

  it 'should respond to a public model method with #method_missing' do
    @articles.should respond_to(:base_model)
  end

  it 'should respond to a belongs_to relationship method with #method_missing' do
    @articles.should respond_to(:original)
  end

  it 'should respond to a has relationship method with #method_missing' do
    @articles.should respond_to(:revisions)
  end

  describe '#method_missing' do
    describe 'with a public model method' do
      before do
        @return = @articles.base_model
      end

      it 'should return expected object' do
        @return.should == @model
      end
    end

    describe 'with a belongs_to relationship method' do
      before do
        @return = @collection = @articles.originals
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return expected Collection' do
        skip = [ DataMapper::Collection, DataMapper::Associations::OneToMany::Proxy ]
        pending_if 'TODO: fix', skip.include?(@articles.class) && !@adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter) do
          @collection.should == [ @original ]
        end
      end
    end

    describe 'with a has relationship method' do
      before do
        # associate the article with children
        @article.revisions << @other
        @article.save
      end

      describe 'with no arguments' do
        before do
          @return = @collection = @articles.revisions
        end

        it 'should return a Collection' do
          @return.should be_kind_of(DataMapper::Collection)
        end

        it 'should return expected Collection' do
          skip = [ DataMapper::Collection, DataMapper::Associations::OneToMany::Proxy ]
          pending_if 'TODO: fix', skip.include?(@articles.class) && !@adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter) do
            @collection.should == [ @other ]
          end
        end
      end

      describe 'with arguments' do
        before do
          @return = @collection = @articles.revisions(:fields => [ :id ])
        end

        it 'should return a Collection' do
          @return.should be_kind_of(DataMapper::Collection)
        end

        it 'should return expected Collection' do
          skip = [ DataMapper::Collection, DataMapper::Associations::OneToMany::Proxy ]
          pending_if 'TODO: fix', skip.include?(@articles.class) && !@adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter) do
            @collection.should == [ @other ]
          end
        end

        { :id => true, :title => false, :content => false }.each do |attribute,expected|
          it "should have query field #{attribute.inspect} #{'not' unless expected} loaded".squeeze(' ') do
            skip = [ DataMapper::Collection, DataMapper::Associations::OneToMany::Proxy ]
            pending_if 'TODO: fix', skip.include?(@articles.class) && !@adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter) do
              @collection.each { |r| r.attribute_loaded?(attribute).should == expected }
            end
          end
        end
      end
    end

    describe 'with an unknown method' do
      it 'should raise an exception' do
        lambda {
          @articles.unknown
        }.should raise_error(NoMethodError)
      end
    end
  end

  it { @articles.should respond_to(:new) }

  describe '#new' do
    before do
      @return = @resource = @articles.new(:content => 'Content')
    end

    it 'should return a Resource' do
      @return.should be_kind_of(DataMapper::Resource)
    end

    it 'should be a Resource with expected attributes' do
      @resource.attributes.only(:content).should == { :content => 'Content' }
    end

    it 'should be a new Resource' do
      @resource.should be_new_record
    end

    it 'should append the Resource to the Collection' do
      @articles.last.should be_equal(@resource)
    end

    it 'should use the query conditions to set default values' do
      @resource.attributes.only(:title).should == { :title => 'Sample Article' }
    end
  end

  it { @articles.should respond_to(:pop) }

  describe '#pop' do
    before do
       @new_article = @articles.create(:title => 'Sample Article')
       @return = @resource = @articles.pop
    end

    it 'should return a Resource' do
      @return.should be_kind_of(DataMapper::Resource)
    end

    it 'should be the last Resource in the Collection' do
      @resource.should == @new_article
    end

    it 'should remove the Resource from the Collection' do
      @articles.should_not include(@resource)
    end

    it 'should orphan the Resource' do
      @resource.collection.should_not be_equal(@articles)
    end
  end

  it { @articles.should respond_to(:push) }

  describe '#push' do
    before do
      @resources = [ @model.new(:title => 'Title 1'), @model.new(:title => 'Title 2') ]
      @return = @articles.push(*@resources)
    end

    it 'should return a Collection' do
      @return.should be_kind_of(DataMapper::Collection)
    end

    it 'should return self' do
      @return.should be_equal(@articles)
    end

    it 'should append the Resources to the Collection' do
      @articles.should == [ @article ] + @resources
    end

    it 'should relate the Resources to the Collection' do
      @resources.each { |r| r.collection.should be_equal(@articles) }
    end
  end

  it { @articles.should respond_to(:reject!) }

  describe '#reject!' do
    describe 'with a block that matches a Resource in the Collection' do
      before do
        @resources = @articles.dup.entries
        @return = @articles.reject! { true }
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      it 'should remove the Resources from the Collection' do
        @resources.each { |r| @articles.should_not include(r) }
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end
    end

    describe 'with a block that does not match a Resource in the Collection' do
      before do
        @resources = @articles.dup.entries
        @return = @articles.reject! { false }
      end

      it 'should return nil' do
        @return.should be_nil
      end

      it 'should not modify the Collection' do
        @articles.should == @resources
      end
    end
  end

  it { @articles.should respond_to(:reload) }

  describe '#reload' do
    describe 'with no arguments' do
      before do
        @resources = @articles.dup.entries
        @return = @collection = @articles.reload
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      { :title => true, :content => false }.each do |attribute,expected|
        it "should have query field #{attribute.inspect} #{'not' unless expected} loaded".squeeze(' ') do
          @collection.each { |r| r.attribute_loaded?(attribute).should == expected }
        end
      end
    end

    describe 'with a Hash query' do
      before do
        @resources = @articles.dup.entries
        @return = @collection = @articles.reload(:fields => [ :content ])  # :title is a default field
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      { :title => true, :content => true }.each do |attribute,expected|
        it "should have query field #{attribute.inspect} #{'not' unless expected} loaded".squeeze(' ') do
          @collection.each { |r| r.attribute_loaded?(attribute).should == expected }
        end
      end
    end

    describe 'with a Query' do
      before do
        @copy = @articles.dup
        @query = DataMapper::Query.new(@repository, @model, :fields => [ :content ])
        @return = @collection = @articles.reload(@query)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      { :title => false }.each do |attribute,expected|
        it "should have query field #{attribute.inspect} #{'not' unless expected} loaded".squeeze(' ') do
          @collection.each { |r| r.attribute_loaded?(attribute).should == expected }
        end
      end
    end
  end

  it { @articles.should respond_to(:replace) }

  describe '#replace' do
    describe 'when provided an Array of Resources' do
      before do
        @resources = @articles.dup.entries
        @return = @articles.replace(@other_articles)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      it 'should update the Collection with new Resources' do
        @articles.should == @other_articles
      end

      it 'should relate each Resource added to the Collection' do
        @articles.each { |r| r.collection.should be_equal(@articles) }
      end

      it 'should orphan each Resource removed from the Collection' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end
    end

    describe 'when provided an Array of Hashes' do
      before do
        @array = [ { :title => 'Hash Article', :content => 'From Hash' } ].freeze
        @return = @articles.replace(@array)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      it 'should initialize a Resource' do
        @return.first.should be_kind_of(DataMapper::Resource)
      end

      it 'should be a new Resource' do
        @return.first.should be_new_record
      end

      it 'should be a Resource with attributes matching the Hash' do
        @return.first.attributes.only(*@array.first.keys).should == @array.first
      end
    end
  end

  it { @articles.should respond_to(:reverse) }

  describe '#reverse' do
    before do
      @new_article = @articles.create(:title => 'Sample Article')
      @return = @articles.reverse
    end

    it 'should return a Collection' do
      @return.should be_kind_of(DataMapper::Collection)
    end

    it 'should return a Collection with reversed entries' do
      @return.should == [ @new_article, @article ]
    end
  end

  it { @articles.should respond_to(:save) }

  describe '#save' do
    describe 'when Resources are not saved' do
      before do
        @articles.new(:title => 'New Article', :content => 'New Article')
        @return = @articles.save
      end

      it 'should return true' do
        @return.should be_true
      end

      it 'should save each Resource' do
        @articles.each { |r| r.should_not be_new_record }
      end
    end

    describe 'when Resources have been orphaned' do
      before do
        @resources = @articles.entries
        @articles.replace([])
        @return = @articles.save
      end

      it 'should return true' do
        @return.should be_true
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end
    end
  end

  it { @articles.should respond_to(:shift) }

  describe '#shift' do
    before do
      @new_article = @articles.create(:title => 'Sample Article')
      @return = @resource = @articles.shift
    end

    it 'should return a Resource' do
      @return.should be_kind_of(DataMapper::Resource)
    end

    it 'should be the first Resource in the Collection' do
      @resource.key.should == @article.key
    end

    it 'should remove the Resource from the Collection' do
      @articles.should_not include(@resource)
    end

    it 'should orphan the Resource' do
      @resource.collection.should_not be_equal(@articles)
    end
  end

  [ :slice, :[] ].each do |method|
    it { @articles.should respond_to(method) }

    describe "##{method}" do
      before do
        1.upto(10) { |n| @articles.create(:content => "Article #{n}") }

        @copy = @articles.dup
      end

      describe 'with a positive offset' do
        before do
          @return = @resource = @articles.send(method, 0)
        end

        it 'should return a Resource' do
          @return.should be_kind_of(DataMapper::Resource)
        end

        it 'should return expected Resource' do
          @return.should == @copy.entries.send(method, 0)
        end

        it 'should not remove the Resource from the Collection' do
          @articles.should include(@resource)
        end

        it 'should relate the Resource to the Collection' do
          @resource.collection.should be_equal(@articles)
        end
      end

      describe 'with a positive offset and length' do
        before do
          @return = @resources = @articles.send(method, 5, 5)
        end

        it 'should return a Collection' do
          @return.should be_kind_of(DataMapper::Collection)
        end

        it 'should return the expected Resource' do
          @return.should == @copy.entries.send(method, 5, 5)
        end

        it 'should not remove the Resources from the Collection' do
          @resources.each { |r| @articles.should include(r) }
        end

        it 'should orphan the Resources' do
          @resources.each { |r| r.collection.should_not be_equal(@articles) }
        end

        it 'should scope the Collection' do
          @resources.reload.should == @copy.entries.send(method, 5, 5)
        end
      end

      describe 'with a positive range' do
        before do
          @return = @resources = @articles.send(method, 5..10)
        end

        it 'should return a Collection' do
          @return.should be_kind_of(DataMapper::Collection)
        end

        it 'should return the expected Resources' do
          @return.should == @copy.entries.send(method, 5..10)
        end

        it 'should not remove the Resources from the Collection' do
          @resources.each { |r| @articles.should include(r) }
        end

        it 'should orphan the Resources' do
          @resources.each { |r| r.collection.should_not be_equal(@articles) }
        end

        it 'should scope the Collection' do
          @resources.reload.should == @copy.entries.send(method, 5..10)
        end
      end

      describe 'with a negative offset' do
        before do
          @return = @resource = @articles.send(method, -1)
        end

        it 'should return a Resource' do
          @return.should be_kind_of(DataMapper::Resource)
        end

        it 'should return expected Resource' do
          @return.should == @copy.entries.send(method, -1)
        end

        it 'should not remove the Resource from the Collection' do
          @articles.should include(@resource)
        end

        it 'should relate the Resource to the Collection' do
          @resource.collection.should be_equal(@articles)
        end
      end

      describe 'with a negative offset and length' do
        before do
          @return = @resources = @articles.send(method, -5, 5)
        end

        it 'should return a Collection' do
          @return.should be_kind_of(DataMapper::Collection)
        end

        it 'should return the expected Resources' do
          @return.should == @copy.entries.send(method, -5, 5)
        end

        it 'should not remove the Resources from the Collection' do
          @resources.each { |r| @articles.should include(r) }
        end

        it 'should orphan the Resources' do
          @resources.each { |r| r.collection.should_not be_equal(@articles) }
        end

        it 'should scope the Collection' do
          @resources.reload.should == @copy.entries.send(method, -5, 5)
        end
      end

      describe 'with a negative range' do
        before do
          @return = @resources = @articles.send(method, -5..-2)
        end

        it 'should return a Collection' do
          @return.should be_kind_of(DataMapper::Collection)
        end

        it 'should return the expected Resources' do
          @return.to_a.should == @copy.entries.send(method, -5..-2)
        end

        it 'should not remove the Resources from the Collection' do
          @resources.each { |r| @articles.should include(r) }
        end

        it 'should orphan the Resources' do
          @resources.each { |r| r.collection.should_not be_equal(@articles) }
        end

        it 'should scope the Collection' do
          @resources.reload.should == @copy.entries.send(method, -5..-2)
        end
      end

      describe 'with an offset not within the Collection' do
        before do
          @return = @articles.send(method, 12)
        end

        it 'should return nil' do
          @return.should be_nil
        end
      end

      describe 'with an offset and length not within the Collection' do
        before do
          @return = @articles.send(method, 12, 1)
        end

        it 'should return nil' do
          @return.should be_nil
        end
      end

      describe 'with a range not within the Collection' do
        before do
          @return = @articles.send(method, 12..13)
        end

        it 'should return nil' do
          @return.should be_nil
        end
      end
    end
  end

  it { @articles.should respond_to(:slice) }

  describe '#slice!' do
    before do
      1.upto(10) { |n| @articles.create(:content => "Article #{n}") }

      @copy = @articles.dup
    end

    describe 'with a positive offset' do
      before do
        @return = @resource = @articles.slice!(0)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @return.key.should == @article.key
      end

      it 'should return the same as Array#slice!' do
        @return.should == @copy.entries.slice!(0)
      end

      it 'should remove the Resource from the Collection' do
        @articles.should_not include(@resource)
      end

      it 'should orphan the Resource' do
        @resource.collection.should_not be_equal(@articles)
      end
    end

    describe 'with a positive offset and length' do
      before do
        @return = @resources = @articles.slice!(5, 5)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return the expected Resource' do
        @return.should == @copy.entries.slice!(5, 5)
      end

      it 'should remove the Resources from the Collection' do
        @resources.each { |r| @articles.should_not include(r) }
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end

      it 'should scope the Collection' do
        @resources.reload.should == @copy.entries.slice!(5, 5)
      end
    end

    describe 'with a positive range' do
      before do
        @return = @resources = @articles.slice!(5..10)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return the expected Resources' do
        @return.should == @copy.entries.slice!(5..10)
      end

      it 'should remove the Resources from the Collection' do
        @resources.each { |r| @articles.should_not include(r) }
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end

      it 'should scope the Collection' do
        @resources.reload.should == @copy.entries.slice!(5..10)
      end
    end

    describe 'with a negative offset' do
      before do
        @return = @resource = @articles.slice!(-1)
      end

      it 'should return a Resource' do
        @return.should be_kind_of(DataMapper::Resource)
      end

      it 'should return expected Resource' do
        @return.should == @copy.entries.slice!(-1)
      end

      it 'should remove the Resource from the Collection' do
        @articles.should_not include(@resource)
      end

      it 'should orphan the Resource' do
        @resource.collection.should_not be_equal(@articles)
      end
    end

    describe 'with a negative offset and length' do
      before do
        @return = @resources = @articles.slice!(-5, 5)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return the expected Resources' do
        @return.should == @copy.entries.slice!(-5, 5)
      end

      it 'should remove the Resources from the Collection' do
        @resources.each { |r| @articles.should_not include(r) }
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end

      it 'should scope the Collection' do
        @resources.reload.should == @copy.entries.slice!(-5, 5)
      end
    end

    describe 'with a negative range' do
      before do
        @return = @resources = @articles.slice!(-3..-2)
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return the expected Resources' do
        @return.should == @copy.entries.slice!(-3..-2)
      end

      it 'should remove the Resources from the Collection' do
        @resources.each { |r| @articles.should_not include(r) }
      end

      it 'should orphan the Resources' do
        @resources.each { |r| r.collection.should_not be_equal(@articles) }
      end

      it 'should scope the Collection' do
        @resources.reload.should == @copy.entries.slice!(-3..-2)
      end
    end

    describe 'with an offset not within the Collection' do
      before do
        @return = @articles.slice!(12)
      end

      it 'should return nil' do
        @return.should be_nil
      end
    end

    describe 'with an offset and length not within the Collection' do
      before do
        @return = @articles.slice!(12, 1)
      end

      it 'should return nil' do
        @return.should be_nil
      end
    end

    describe 'with a range not within the Collection' do
      before do
        @return = @articles.slice!(12..13)
      end

      it 'should return nil' do
        @return.should be_nil
      end
    end
  end

  it { @articles.should respond_to(:sort!) }

  describe '#sort!' do
    describe 'without a block' do
      before do
        @return = @articles.unshift(@other).sort!
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      it 'should modify and sort the Collection using default sort order' do
        @articles.should == [ @article, @other ]
      end
    end

    describe 'with a block' do
      before do
        @return = @articles.unshift(@other).sort! { |a,b| b.id <=> a.id }
      end

      it 'should return a Collection' do
        @return.should be_kind_of(DataMapper::Collection)
      end

      it 'should return self' do
        @return.should be_equal(@articles)
      end

      it 'should modify and sort the Collection using supplied block' do
        @articles.should == [ @other, @article ]
      end
    end
  end

  [ :splice, :[]= ].each do |method|
    it { @articles.should respond_to(method) }

    describe "##{method}" do
      before do
        orphans = (1..10).map do |n|
          @articles.create(:content => "Article #{n}")
          @articles.pop  # remove the article from the tail
        end

        @articles.unshift(*orphans.first(5))
        @articles.concat(orphans.last(5))

        @copy = @articles.dup
        @new = @model.new(:content => 'New Article')
      end

      describe 'with a positive offset and a Resource' do
        before do
          @original = @copy[1]
          @original.collection.should be_equal(@articles)

          @return = @resource = @articles.send(method, 1, @new)
        end

        it 'should return a Resource' do
          @return.should be_kind_of(DataMapper::Resource)
        end

        it 'should return expected Resource' do
          @return.should be_equal(@new)
        end

        it 'should return the same as Array#[]=' do
          @return.should == @copy.entries[1] = @new
        end

        it 'should include the Resource in the Collection' do
          @articles.should include(@resource)
        end

        it 'should relate the Resource to the Collection' do
          @resource.collection.should be_equal(@articles)
        end

        it 'should orphan the original Resource' do
          @original.collection.should_not be_equal(@articles)
        end
      end

      describe 'with a positive offset and length and a Resource' do
        before do
          @original = @copy[2]
          @original.collection.should be_equal(@articles)

          @return = @resource = @articles.send(method, 2, 1, @new)
        end

        it 'should return a Resource' do
          @return.should be_kind_of(DataMapper::Resource)
        end

        it 'should return the expected Resource' do
          @return.should be_equal(@new)
        end

        it 'should return the same as Array#[]=' do
          @return.should == @copy.entries[2, 1] = @new
        end

        it 'should include the Resource in the Collection' do
          @articles.should include(@resource)
        end

        it 'should orphan the original Resource' do
          @original.collection.should_not be_equal(@articles)
        end
      end

      describe 'with a positive range and a Resource' do
        before do
          @originals = @copy.values_at(2..3)
          @originals.each { |o| o.collection.should be_equal(@articles) }

          @return = @resource = @articles.send(method, 2..3, @new)
        end

        it 'should return a Resource' do
          @return.should be_kind_of(DataMapper::Resource)
        end

        it 'should return the expected Resources' do
          @return.should be_equal(@new)
        end

        it 'should return the same as Array#[]=' do
          @return.should == @copy.entries[2..3] = @new
        end

        it 'should include the Resource in the Collection' do
          @articles.should include(@resource)
        end

        it 'should orphan the original Resources' do
          @originals.each { |o| o.collection.should_not be_equal(@articles) }
        end
      end

      describe 'with a negative offset and a Resource' do
        before do
          @original = @copy[-1]
          @original.collection.should be_equal(@articles)

          @return = @resource = @articles.send(method, -1, @new)
        end

        it 'should return a Resource' do
          @return.should be_kind_of(DataMapper::Resource)
        end

        it 'should return expected Resource' do
          @return.should be_equal(@new)
        end

        it 'should return the same as Array#[]=' do
          @return.should == @copy.entries[-1] = @new
        end

        it 'should include the Resource in the Collection' do
          @articles.should include(@resource)
        end

        it 'should relate the Resource to the Collection' do
          @resource.collection.should be_equal(@articles)
        end

        it 'should orphan the original Resource' do
          @original.collection.should_not be_equal(@articles)
        end
      end

      describe 'with a negative offset and length and a Resource' do
        before do
          @original = @copy[-2]
          @original.collection.should be_equal(@articles)

          @return = @resource = @articles.send(method, -2, 1, @new)
        end

        it 'should return a Resource' do
          @return.should be_kind_of(DataMapper::Resource)
        end

        it 'should return the expected Resource' do
          @return.should be_equal(@new)
        end

        it 'should return the same as Array#[]=' do
          @return.should == @copy.entries[-2, 1] = @new
        end

        it 'should include the Resource in the Collection' do
          @articles.should include(@resource)
        end

        it 'should orphan the original Resource' do
          @original.collection.should_not be_equal(@articles)
        end
      end

      describe 'with a negative range and a Resource' do
        before do
          @originals = @copy.values_at(-3..-2)
          @originals.each { |o| o.collection.should be_equal(@articles) }

          @return = @resource = @articles.send(method, -3..-2, @new)
        end

        it 'should return a Resource' do
          @return.should be_kind_of(DataMapper::Resource)
        end

        it 'should return the expected Resources' do
          @return.should be_equal(@new)
        end

        it 'should return the same as Array#[]=' do
          @return.should == @copy.entries[-3..-2] = @new
        end

        it 'should include the Resource in the Collection' do
          @articles.should include(@resource)
        end

        it 'should orphan the original Resources' do
          @originals.each { |o| o.collection.should_not be_equal(@articles) }
        end
      end
    end
  end

  it { @articles.should respond_to(:unshift) }

  describe '#unshift' do
    before do
      @resources = [ @model.new(:title => 'Title 1'), @model.new(:title => 'Title 2') ]
      @return = @articles.unshift(*@resources)
    end

    it 'should return a Collection' do
      @return.should be_kind_of(DataMapper::Collection)
    end

    it 'should return self' do
      @return.should be_equal(@articles)
    end

    it 'should prepend the Resources to the Collection' do
      @articles.should == @resources + [ @article ]
    end

    it 'should relate the Resources to the Collection' do
      @resources.each { |r| r.collection.should be_equal(@articles) }
    end
  end

  it { @articles.should respond_to(:update) }

  describe '#update' do
    describe 'with no arguments' do
      before do
        @return = @articles.update
      end

      it 'should return true' do
        @return.should be_true
      end
    end

    describe 'with attributes' do
      before do
        @attributes = { :title => 'Updated Title' }
        @return = @articles.update(@attributes)
      end

      it 'should return true' do
        @return.should be_true
      end

      it 'should update attributes of all Resources' do
        @articles.each { |r| @attributes.each { |k,v| r.send(k).should == v } }
      end

      it 'should persist the changes' do
        resource = @model.get(*@article.key)
        @attributes.each { |k,v| resource.send(k).should == v }
      end
    end

    describe 'with attributes and allowed properties' do
      before do
        @attributes = { :title => 'Updated Title' }
        @allowed = [ :title ]
        @return = @articles.update(@attributes, *@allowed)
      end

      it 'should return true' do
        @return.should be_true
      end

      it 'should update allowed attributes of all Resources' do
        @articles.each { |r| @attributes.each { |k,v| r.send(k).should == v } }
      end

      it 'should persist the changed attributes' do
        resource = @model.get(*@article.key)
        @attributes.each { |k,v| resource.send(k).should == v }
      end
    end

    describe 'with attributes and allowed properties not matching the attributes' do
      before do
        @attributes = { :title => 'Updated Title', :content => 'Updated Content' }
        @allowed = [ :title ]
        @return = @articles.update(@attributes, *@allowed)
      end

      it 'should return true' do
        @return.should be_true
      end

      it 'should update allowed attributes of all Resources' do
        @attributes.only(*@allowed).each { |k,v| @articles.each { |r| r.send(k).should == v } }
      end

      it 'should not update disallowed attributes of any Resources' do
        @attributes.except(*@allowed).each { |k,v| @articles.each { |r| r.send(k).should_not == v } }
      end

      it 'should persist the changed attributes' do
        resource = @model.get(*@article.key)
        @attributes.only(*@allowed).each { |k,v| resource.send(k).should == v }
      end
    end

    describe 'with attributes where one is a parent association' do
      before do
        @attributes = { :original => @other }
        @return = @articles.update(@attributes)
      end

      it 'should return true' do
        @return.should be_true
      end

      it 'should update attributes of all Resources' do
        @articles.each { |r| @attributes.each { |k,v| r.send(k).should == v } }
      end

      it 'should persist the changes' do
        resource = @model.get(*@article.key)
        @attributes.each { |k,v| resource.send(k).should == v }
      end
    end
  end

  it { @articles.should respond_to(:update!) }

  describe '#update!' do
    describe 'with no arguments' do
      before do
        @return = @articles.update!
      end

      it 'should return true' do
        @return.should be_true
      end
    end

    describe 'with attributes' do
      before do
        @attributes = { :title => 'Updated Title' }
        @return = @articles.update!(@attributes)
      end

      it 'should return true' do
        @return.should be_true
      end

      it 'should bypass validation' do
        pending 'TODO: not sure how to best spec this'
      end

      it 'should update attributes of all Resources' do
        @articles.each { |r| @attributes.each { |k,v| r.send(k).should == v } }
      end

      it 'should persist the changes' do
        resource = @model.get(*@article.key)
        @attributes.each { |k,v| resource.send(k).should == v }
      end
    end

    describe 'with attributes and allowed properties' do
      before do
        @attributes = { :title => 'Updated Title' }
        @allowed = [ :title ]
        @return = @articles.update!(@attributes, *@allowed)
      end

      it 'should return true' do
        @return.should be_true
      end

      it 'should bypass validation' do
        pending 'TODO: not sure how to best spec this'
      end

      it 'should update allowed attributes of all Resources' do
        @articles.each { |r| @attributes.each { |k,v| r.send(k).should == v } }
      end

      it 'should persist the changes' do
        resource = @model.get(*@article.key)
        @attributes.each { |k,v| resource.send(k).should == v }
      end
    end

    describe 'with attributes and allowed properties not matching the attributes' do
      before do
        @attributes = { :title => 'Updated Title', :content => 'Updated Content' }
        @allowed = [ :title ]
        @return = @articles.update!(@attributes, *@allowed)
      end

      it 'should return true' do
        @return.should be_true
      end

      it 'should bypass validation' do
        pending 'TODO: not sure how to best spec this'
      end

      it 'should update allowed attributes of all Resources' do
        @attributes.only(*@allowed).each { |k,v| @articles.each { |r| r.send(k).should == v } }
      end

      it 'should not update disallowed attributes of any Resources' do
        @attributes.except(*@allowed).each { |k,v| @articles.each { |r| r.send(k).should_not == v } }
      end

      it 'should persist the changes' do
        resource = @model.get(*@article.key)
        @attributes.only(*@allowed).each { |k,v| resource.send(k).should == v }
      end
    end

    describe 'with attributes where one is a parent association' do
      before do
        @attributes = { :original => @other }
        @return = @articles.update!(@attributes)
      end

      it 'should return true' do
        @return.should be_true
      end

      it 'should update attributes of all Resources' do
        skip = [ DataMapper::Collection, DataMapper::Associations::OneToMany::Proxy ]
        pending_if 'TODO: fix bug with IdentityMap and InMemoryAdapter', skip.include?(@articles.class) && !@articles.loaded? && @adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter) do
          @articles.each { |r| @attributes.each { |k,v| r.send(k).should == v } }
        end
      end

      it 'should persist the changes' do
        resource = @model.get(*@article.key)
        @attributes.each { |k,v| resource.send(k).should == v }
      end
    end
  end
end

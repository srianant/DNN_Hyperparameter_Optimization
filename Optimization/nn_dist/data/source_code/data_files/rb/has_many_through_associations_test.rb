require "cases/helper"
require "models/post"
require "models/person"
require "models/reference"
require "models/job"
require "models/reader"
require "models/comment"
require "models/rating"
require "models/tag"
require "models/tagging"
require "models/author"
require "models/owner"
require "models/pet"
require "models/pet_treasure"
require "models/toy"
require "models/treasure"
require "models/contract"
require "models/company"
require "models/developer"
require "models/computer"
require "models/subscriber"
require "models/book"
require "models/subscription"
require "models/essay"
require "models/category"
require "models/categorization"
require "models/member"
require "models/membership"
require "models/club"
require "models/organization"

class HasManyThroughAssociationsTest < ActiveRecord::TestCase
  fixtures :posts, :readers, :people, :comments, :authors, :categories, :taggings, :tags,
           :owners, :pets, :toys, :jobs, :references, :companies, :members, :author_addresses,
           :subscribers, :books, :subscriptions, :developers, :categorizations, :essays,
           :categories_posts, :clubs, :memberships, :organizations

  # Dummies to force column loads so query counts are clean.
  def setup
    Person.create first_name: "gummy"
    Reader.create person_id: 0, post_id: 0
  end

  def test_preload_sti_rhs_class
    developers = Developer.includes(:firms).all.to_a
    assert_no_queries do
      developers.each(&:firms)
    end
  end

  def test_preload_sti_middle_relation
    club = Club.create!(name: "Aaron cool banana club")
    member1 = Member.create!(name: "Aaron")
    member2 = Member.create!(name: "Cat")

    SuperMembership.create! club: club, member: member1
    CurrentMembership.create! club: club, member: member2

    club1 = Club.includes(:members).find_by_id club.id
    assert_equal [member1, member2].sort_by(&:id),
                 club1.members.sort_by(&:id)
  end

  def make_model(name)
    Class.new(ActiveRecord::Base) { define_singleton_method(:name) { name } }
  end

  def test_ordered_has_many_through
    person_prime = Class.new(ActiveRecord::Base) do
      def self.name; "Person"; end

      has_many :readers
      has_many :posts, -> { order("posts.id DESC") }, through: :readers
    end
    posts = person_prime.includes(:posts).first.posts

    assert_operator posts.length, :>, 1
    posts.each_cons(2) do |left, right|
      assert_operator left.id, :>, right.id
    end
  end

  def test_singleton_has_many_through
    book         = make_model "Book"
    subscription = make_model "Subscription"
    subscriber   = make_model "Subscriber"

    subscriber.primary_key = "nick"
    subscription.belongs_to :book,       anonymous_class: book
    subscription.belongs_to :subscriber, anonymous_class: subscriber

    book.has_many :subscriptions, anonymous_class: subscription
    book.has_many :subscribers, through: :subscriptions, anonymous_class: subscriber

    anonbook = book.first
    namebook = Book.find anonbook.id

    assert_operator anonbook.subscribers.count, :>, 0
    anonbook.subscribers.each do |s|
      assert_instance_of subscriber, s
    end
    assert_equal namebook.subscribers.map(&:id).sort,
                 anonbook.subscribers.map(&:id).sort
  end

  def test_no_pk_join_table_append
    lesson, _, student = make_no_pk_hm_t

    sicp = lesson.new(name: "SICP")
    ben = student.new(name: "Ben Bitdiddle")
    sicp.students << ben
    assert sicp.save!
  end

  def test_no_pk_join_table_delete
    lesson, lesson_student, student = make_no_pk_hm_t

    sicp = lesson.new(name: "SICP")
    ben = student.new(name: "Ben Bitdiddle")
    louis = student.new(name: "Louis Reasoner")
    sicp.students << ben
    sicp.students << louis
    assert sicp.save!

    sicp.students.reload
    assert_operator lesson_student.count, :>=, 2
    assert_no_difference("student.count") do
      assert_difference("lesson_student.count", -2) do
        sicp.students.destroy(*student.all.to_a)
      end
    end
  end

  def test_no_pk_join_model_callbacks
    lesson, lesson_student, student = make_no_pk_hm_t

    after_destroy_called = false
    lesson_student.after_destroy do
      after_destroy_called = true
    end

    sicp = lesson.new(name: "SICP")
    ben = student.new(name: "Ben Bitdiddle")
    sicp.students << ben
    assert sicp.save!

    sicp.students.reload
    sicp.students.destroy(*student.all.to_a)
    assert after_destroy_called, "after destroy should be called"
  end

  def make_no_pk_hm_t
    lesson = make_model "Lesson"
    student = make_model "Student"

    lesson_student = make_model "LessonStudent"
    lesson_student.table_name = "lessons_students"

    lesson_student.belongs_to :lesson, anonymous_class: lesson
    lesson_student.belongs_to :student, anonymous_class: student
    lesson.has_many :lesson_students, anonymous_class: lesson_student
    lesson.has_many :students, through: :lesson_students, anonymous_class: student
    [lesson, lesson_student, student]
  end

  def test_pk_is_not_required_for_join
    post  = Post.includes(:scategories).first
    post2 = Post.includes(:categories).first

    assert_operator post.categories.length, :>, 0
    assert_equal post2.categories, post.categories
  end

  def test_include?
    person = Person.new
    post = Post.new
    person.posts << post
    assert_includes person.posts, post
  end

  def test_associate_existing
    post   = posts(:thinking)
    person = people(:david)

    assert_queries(1) do
      post.people << person
    end

    assert_queries(1) do
      assert_includes post.people, person
    end

    assert_includes post.reload.people.reload, person
  end

  def test_delete_all_for_with_dependent_option_destroy
    person = people(:david)
    assert_equal 1, person.jobs_with_dependent_destroy.count

    assert_no_difference "Job.count" do
      assert_difference "Reference.count", -1 do
        person.reload.jobs_with_dependent_destroy.delete_all
      end
    end
  end

  def test_delete_all_for_with_dependent_option_nullify
    person = people(:david)
    assert_equal 1, person.jobs_with_dependent_nullify.count

    assert_no_difference "Job.count" do
      assert_no_difference "Reference.count" do
        person.reload.jobs_with_dependent_nullify.delete_all
      end
    end
  end

  def test_delete_all_for_with_dependent_option_delete_all
    person = people(:david)
    assert_equal 1, person.jobs_with_dependent_delete_all.count

    assert_no_difference "Job.count" do
      assert_difference "Reference.count", -1 do
        person.reload.jobs_with_dependent_delete_all.delete_all
      end
    end
  end

  def test_concat
    person = people(:david)
    post   = posts(:thinking)
    post.people.concat [person]
    assert_equal 1, post.people.size
    assert_equal 1, post.people.reload.size
  end

  def test_associate_existing_record_twice_should_add_to_target_twice
    post   = posts(:thinking)
    person = people(:david)

    assert_difference "post.people.to_a.count", 2 do
      post.people << person
      post.people << person
    end
  end

  def test_associate_existing_record_twice_should_add_records_twice
    post   = posts(:thinking)
    person = people(:david)

    assert_difference "post.people.count", 2 do
      post.people << person
      post.people << person
    end
  end

  def test_add_two_instance_and_then_deleting
    post   = posts(:thinking)
    person = people(:david)

    post.people << person
    post.people << person

    counts = ["post.people.count", "post.people.to_a.count", "post.readers.count", "post.readers.to_a.count"]
    assert_difference counts, -2 do
      post.people.delete(person)
    end

    assert_not_includes post.people.reload, person
  end

  def test_associating_new
    assert_queries(1) { posts(:thinking) }
    new_person = nil # so block binding catches it

    assert_queries(0) do
      new_person = Person.new first_name: "bob"
    end

    # Associating new records always saves them
    # Thus, 1 query for the new person record, 1 query for the new join table record
    assert_queries(2) do
      posts(:thinking).people << new_person
    end

    assert_queries(1) do
      assert_includes posts(:thinking).people, new_person
    end

    assert_includes posts(:thinking).reload.people.reload, new_person
  end

  def test_associate_new_by_building
    assert_queries(1) { posts(:thinking) }

    assert_queries(0) do
      posts(:thinking).people.build(first_name: "Bob")
      posts(:thinking).people.new(first_name: "Ted")
    end

    # Should only need to load the association once
    assert_queries(1) do
      assert_includes posts(:thinking).people.collect(&:first_name), "Bob"
      assert_includes posts(:thinking).people.collect(&:first_name), "Ted"
    end

    # 2 queries for each new record (1 to save the record itself, 1 for the join model)
    #    * 2 new records = 4
    # + 1 query to save the actual post = 5
    assert_queries(5) do
      posts(:thinking).body += "-changed"
      posts(:thinking).save
    end

    assert_includes posts(:thinking).reload.people.reload.collect(&:first_name), "Bob"
    assert_includes posts(:thinking).reload.people.reload.collect(&:first_name), "Ted"
  end

  def test_build_then_save_with_has_many_inverse
    post   = posts(:thinking)
    person = post.people.build(first_name: "Bob")
    person.save
    post.reload

    assert_includes post.people, person
  end

  def test_build_then_save_with_has_one_inverse
    post   = posts(:thinking)
    person = post.single_people.build(first_name: "Bob")
    person.save
    post.reload

    assert_includes post.single_people, person
  end

  def test_both_parent_ids_set_when_saving_new
    post = Post.new(title: "Hello", body: "world")
    person = Person.new(first_name: "Sean")

    post.people = [person]
    post.save

    assert post.id
    assert person.id
    assert_equal post.id, post.readers.first.post_id
    assert_equal person.id, post.readers.first.person_id
  end

  def test_delete_association
    assert_queries(2) { posts(:welcome);people(:michael); }

    assert_queries(1) do
      posts(:welcome).people.delete(people(:michael))
    end

    assert_queries(1) do
      assert posts(:welcome).people.empty?
    end

    assert posts(:welcome).reload.people.reload.empty?
  end

  def test_destroy_association
    assert_no_difference "Person.count" do
      assert_difference "Reader.count", -1 do
        posts(:welcome).people.destroy(people(:michael))
      end
    end

    assert posts(:welcome).reload.people.empty?
    assert posts(:welcome).people.reload.empty?
  end

  def test_destroy_all
    assert_no_difference "Person.count" do
      assert_difference "Reader.count", -1 do
        posts(:welcome).people.destroy_all
      end
    end

    assert posts(:welcome).reload.people.empty?
    assert posts(:welcome).people.reload.empty?
  end

  def test_should_raise_exception_for_destroying_mismatching_records
    assert_no_difference ["Person.count", "Reader.count"] do
      assert_raise(ActiveRecord::AssociationTypeMismatch) { posts(:welcome).people.destroy(posts(:thinking)) }
    end
  end

  def test_delete_through_belongs_to_with_dependent_nullify
    Reference.make_comments = true

    person    = people(:michael)
    job       = jobs(:magician)
    reference = Reference.where(job_id: job.id, person_id: person.id).first

    assert_no_difference ["Job.count", "Reference.count"] do
      assert_difference "person.jobs.count", -1 do
        person.jobs_with_dependent_nullify.delete(job)
      end
    end

    assert_equal nil, reference.reload.job_id
  ensure
    Reference.make_comments = false
  end

  def test_delete_through_belongs_to_with_dependent_delete_all
    Reference.make_comments = true

    person = people(:michael)
    job    = jobs(:magician)

    # Make sure we're not deleting everything
    assert person.jobs.count >= 2

    assert_no_difference "Job.count" do
      assert_difference ["person.jobs.count", "Reference.count"], -1 do
        person.jobs_with_dependent_delete_all.delete(job)
      end
    end

    # Check that the destroy callback on Reference did not run
    assert_equal nil, person.reload.comments
  ensure
    Reference.make_comments = false
  end

  def test_delete_through_belongs_to_with_dependent_destroy
    Reference.make_comments = true

    person = people(:michael)
    job    = jobs(:magician)

    # Make sure we're not deleting everything
    assert person.jobs.count >= 2

    assert_no_difference "Job.count" do
      assert_difference ["person.jobs.count", "Reference.count"], -1 do
        person.jobs_with_dependent_destroy.delete(job)
      end
    end

    # Check that the destroy callback on Reference ran
    assert_equal "Reference destroyed", person.reload.comments
  ensure
    Reference.make_comments = false
  end

  def test_belongs_to_with_dependent_destroy
    person = PersonWithDependentDestroyJobs.find(1)

    # Create a reference which is not linked to a job. This should not be destroyed.
    person.references.create!

    assert_no_difference "Job.count" do
      assert_difference "Reference.count", -person.jobs.count do
        person.destroy
      end
    end
  end

  def test_belongs_to_with_dependent_delete_all
    person = PersonWithDependentDeleteAllJobs.find(1)

    # Create a reference which is not linked to a job. This should not be destroyed.
    person.references.create!

    assert_no_difference "Job.count" do
      assert_difference "Reference.count", -person.jobs.count do
        person.destroy
      end
    end
  end

  def test_belongs_to_with_dependent_nullify
    person = PersonWithDependentNullifyJobs.find(1)

    references = person.references.to_a

    assert_no_difference ["Reference.count", "Job.count"] do
      person.destroy
    end

    references.each do |reference|
      assert_equal nil, reference.reload.job_id
    end
  end

  def test_update_counter_caches_on_delete
    post = posts(:welcome)
    tag  = post.tags.create!(name: "doomed")

    assert_difference ["post.reload.tags_count"], -1 do
      posts(:welcome).tags.delete(tag)
    end
  end

  def test_update_counter_caches_on_delete_with_dependent_destroy
    post = posts(:welcome)
    tag  = post.tags.create!(name: "doomed")
    post.update_columns(tags_with_destroy_count: post.tags.count)

    assert_difference ["post.reload.tags_with_destroy_count"], -1 do
      posts(:welcome).tags_with_destroy.delete(tag)
    end
  end

  def test_update_counter_caches_on_delete_with_dependent_nullify
    post = posts(:welcome)
    tag  = post.tags.create!(name: "doomed")
    post.update_columns(tags_with_nullify_count: post.tags.count)

    assert_no_difference "post.reload.tags_count" do
      assert_difference "post.reload.tags_with_nullify_count", -1 do
        posts(:welcome).tags_with_nullify.delete(tag)
      end
    end
  end

  def test_update_counter_caches_on_replace_association
    post = posts(:welcome)
    tag  = post.tags.create!(name: "doomed")
    tag.tagged_posts << posts(:thinking)

    tag.tagged_posts = []
    post.reload

    assert_equal(post.taggings.count, post.tags_count)
  end

  def test_update_counter_caches_on_destroy
    post = posts(:welcome)
    tag  = post.tags.create!(name: "doomed")

    assert_difference "post.reload.tags_count", -1 do
      tag.tagged_posts.destroy(post)
    end
  end

  def test_replace_association
    assert_queries(4) { posts(:welcome);people(:david);people(:michael); posts(:welcome).people.reload }

    # 1 query to delete the existing reader (michael)
    # 1 query to associate the new reader (david)
    assert_queries(2) do
      posts(:welcome).people = [people(:david)]
    end

    assert_queries(0) {
      assert_includes posts(:welcome).people, people(:david)
      assert_not_includes posts(:welcome).people, people(:michael)
    }

    assert_includes posts(:welcome).reload.people.reload, people(:david)
    assert_not_includes posts(:welcome).reload.people.reload, people(:michael)
  end

  def test_replace_order_is_preserved
    posts(:welcome).people.clear
    posts(:welcome).people = [people(:david), people(:michael)]
    assert_equal [people(:david).id, people(:michael).id], posts(:welcome).readers.order("id").map(&:person_id)

    # Test the inverse order in case the first success was a coincidence
    posts(:welcome).people.clear
    posts(:welcome).people = [people(:michael), people(:david)]
    assert_equal [people(:michael).id, people(:david).id], posts(:welcome).readers.order("id").map(&:person_id)
  end

  def test_replace_by_id_order_is_preserved
    posts(:welcome).people.clear
    posts(:welcome).person_ids = [people(:david).id, people(:michael).id]
    assert_equal [people(:david).id, people(:michael).id], posts(:welcome).readers.order("id").map(&:person_id)

    # Test the inverse order in case the first success was a coincidence
    posts(:welcome).people.clear
    posts(:welcome).person_ids = [people(:michael).id, people(:david).id]
    assert_equal [people(:michael).id, people(:david).id], posts(:welcome).readers.order("id").map(&:person_id)
  end

  def test_associate_with_create
    assert_queries(1) { posts(:thinking) }

    # 1 query for the new record, 1 for the join table record
    # No need to update the actual collection yet!
    assert_queries(2) do
      posts(:thinking).people.create(first_name: "Jeb")
    end

    # *Now* we actually need the collection so it's loaded
    assert_queries(1) do
      assert_includes posts(:thinking).people.collect(&:first_name), "Jeb"
    end

    assert_includes posts(:thinking).reload.people.reload.collect(&:first_name), "Jeb"
  end

  def test_through_record_is_built_when_created_with_where
    assert_difference("posts(:thinking).readers.count", 1) do
      posts(:thinking).people.where(first_name: "Jeb").create
    end
  end

  def test_associate_with_create_and_no_options
    peeps = posts(:thinking).people.count
    posts(:thinking).people.create(first_name: "foo")
    assert_equal peeps + 1, posts(:thinking).people.count
  end

  def test_associate_with_create_with_through_having_conditions
    impatient_people = posts(:thinking).impatient_people.count
    posts(:thinking).impatient_people.create!(first_name: "foo")
    assert_equal impatient_people + 1, posts(:thinking).impatient_people.count
  end

  def test_associate_with_create_exclamation_and_no_options
    peeps = posts(:thinking).people.count
    posts(:thinking).people.create!(first_name: "foo")
    assert_equal peeps + 1, posts(:thinking).people.count
  end

  def test_create_on_new_record
    p = Post.new

    error = assert_raises(ActiveRecord::RecordNotSaved) { p.people.create(first_name: "mew") }
    assert_equal "You cannot call create unless the parent is saved", error.message

    error = assert_raises(ActiveRecord::RecordNotSaved) { p.people.create!(first_name: "snow") }
    assert_equal "You cannot call create unless the parent is saved", error.message
  end

  def test_associate_with_create_and_invalid_options
    firm = companies(:first_firm)
    assert_no_difference("firm.developers.count") { assert_nothing_raised { firm.developers.create(name: "0") } }
  end

  def test_associate_with_create_and_valid_options
    firm = companies(:first_firm)
    assert_difference("firm.developers.count", 1) { firm.developers.create(name: "developer") }
  end

  def test_associate_with_create_bang_and_invalid_options
    firm = companies(:first_firm)
    assert_no_difference("firm.developers.count") { assert_raises(ActiveRecord::RecordInvalid) { firm.developers.create!(name: "0") } }
  end

  def test_associate_with_create_bang_and_valid_options
    firm = companies(:first_firm)
    assert_difference("firm.developers.count", 1) { firm.developers.create!(name: "developer") }
  end

  def test_push_with_invalid_record
    firm = companies(:first_firm)
    assert_raises(ActiveRecord::RecordInvalid) { firm.developers << Developer.new(name: "0") }
  end

  def test_push_with_invalid_join_record
    repair_validations(Contract) do
      Contract.validate { |r| r.errors[:base] << "Invalid Contract" }

      firm = companies(:first_firm)
      lifo = Developer.new(name: "lifo")
      assert_raises(ActiveRecord::RecordInvalid) { firm.developers << lifo }

      lifo = Developer.create!(name: "lifo")
      assert_raises(ActiveRecord::RecordInvalid) { firm.developers << lifo }
    end
  end

  def test_clear_associations
    assert_queries(2) { posts(:welcome);posts(:welcome).people.reload }

    assert_queries(1) do
      posts(:welcome).people.clear
    end

    assert_queries(0) do
      assert posts(:welcome).people.empty?
    end

    assert posts(:welcome).reload.people.reload.empty?
  end

  def test_association_callback_ordering
    Post.reset_log
    log = Post.log
    post = posts(:thinking)

    post.people_with_callbacks << people(:michael)
    assert_equal [
      [:added, :before, "Michael"],
      [:added, :after, "Michael"]
    ], log.last(2)

    post.people_with_callbacks.push(people(:david), Person.create!(first_name: "Bob"), Person.new(first_name: "Lary"))
    assert_equal [
      [:added, :before, "David"],
      [:added, :after, "David"],
      [:added, :before, "Bob"],
      [:added, :after, "Bob"],
      [:added, :before, "Lary"],
      [:added, :after, "Lary"]
    ], log.last(6)

    post.people_with_callbacks.build(first_name: "Ted")
    assert_equal [
      [:added, :before, "Ted"],
      [:added, :after, "Ted"]
    ], log.last(2)

    post.people_with_callbacks.create(first_name: "Sam")
    assert_equal [
      [:added, :before, "Sam"],
      [:added, :after, "Sam"]
    ], log.last(2)

    post.people_with_callbacks = [people(:michael), people(:david), Person.new(first_name: "Julian"), Person.create!(first_name: "Roger")]
    assert_equal((%w(Ted Bob Sam Lary) * 2).sort, log[-12..-5].collect(&:last).sort)
    assert_equal [
      [:added, :before, "Julian"],
      [:added, :after, "Julian"],
      [:added, :before, "Roger"],
      [:added, :after, "Roger"]
    ], log.last(4)
  end

  def test_dynamic_find_should_respect_association_include
    # SQL error in sort clause if :include is not included
    # due to Unknown column 'comments.id'
    assert Person.find(1).posts_with_comments_sorted_by_comment_id.find_by_title("Welcome to the weblog")
  end

  def test_count_with_include_should_alias_join_table
    assert_equal 2, people(:michael).posts.includes(:readers).count
  end

  def test_inner_join_with_quoted_table_name
    assert_equal 2, people(:michael).jobs.size
  end

  def test_get_ids
    assert_equal [posts(:welcome).id, posts(:authorless).id].sort, people(:michael).post_ids.sort
  end

  def test_get_ids_for_has_many_through_with_conditions_should_not_preload
    Tagging.create!(taggable_type: "Post", taggable_id: posts(:welcome).id, tag: tags(:misc))
    assert_not_called(ActiveRecord::Associations::Preloader, :new) do
      posts(:welcome).misc_tag_ids
    end
  end

  def test_get_ids_for_loaded_associations
    person = people(:michael)
    person.posts.reload
    assert_queries(0) do
      person.post_ids
      person.post_ids
    end
  end

  def test_get_ids_for_unloaded_associations_does_not_load_them
    person = people(:michael)
    assert !person.posts.loaded?
    assert_equal [posts(:welcome).id, posts(:authorless).id].sort, person.post_ids.sort
    assert !person.posts.loaded?
  end

  def test_association_proxy_transaction_method_starts_transaction_in_association_class
    assert_called(Tag, :transaction) do
      Post.first.tags.transaction do
        # nothing
      end
    end
  end

  def test_has_many_association_through_a_belongs_to_association_where_the_association_doesnt_exist
    post = Post.create!(title: "TITLE", body: "BODY")
    assert_equal [], post.author_favorites
  end

  def test_has_many_association_through_a_belongs_to_association
    author = authors(:mary)
    post = Post.create!(author: author, title: "TITLE", body: "BODY")
    author.author_favorites.create(favorite_author_id: 1)
    author.author_favorites.create(favorite_author_id: 2)
    author.author_favorites.create(favorite_author_id: 3)
    assert_equal post.author.author_favorites, post.author_favorites
  end

  def test_merge_join_association_with_has_many_through_association_proxy
    author = authors(:mary)
    assert_nothing_raised { author.comments.ratings.to_sql }
  end

  def test_has_many_association_through_a_has_many_association_with_nonstandard_primary_keys
    assert_equal 2, owners(:blackbeard).toys.count
  end

  def test_find_on_has_many_association_collection_with_include_and_conditions
    post_with_no_comments = people(:michael).posts_with_no_comments.first
    assert_equal post_with_no_comments, posts(:authorless)
  end

  def test_has_many_through_has_one_reflection
    assert_equal [comments(:eager_sti_on_associations_vs_comment)], authors(:david).very_special_comments
  end

  def test_modifying_has_many_through_has_one_reflection_should_raise
    [
      lambda { authors(:david).very_special_comments = [VerySpecialComment.create!(body: "Gorp!", post_id: 1011), VerySpecialComment.create!(body: "Eep!", post_id: 1012)] },
      lambda { authors(:david).very_special_comments << VerySpecialComment.create!(body: "Hoohah!", post_id: 1013) },
      lambda { authors(:david).very_special_comments.delete(authors(:david).very_special_comments.first) },
    ].each { |block| assert_raise(ActiveRecord::HasManyThroughCantAssociateThroughHasOneOrManyReflection, &block) }
  end

  def test_has_many_association_through_a_has_many_association_to_self
    sarah = Person.create!(first_name: "Sarah", primary_contact_id: people(:susan).id, gender: "F", number1_fan_id: 1)
    john = Person.create!(first_name: "John", primary_contact_id: sarah.id, gender: "M", number1_fan_id: 1)
    assert_equal sarah.agents, [john]
    assert_equal people(:susan).agents.flat_map(&:agents), people(:susan).agents_of_agents
  end

  def test_associate_existing_with_nonstandard_primary_key_on_belongs_to
    Categorization.create(author: authors(:mary), named_category_name: categories(:general).name)
    assert_equal categories(:general), authors(:mary).named_categories.first
  end

  def test_collection_build_with_nonstandard_primary_key_on_belongs_to
    author   = authors(:mary)
    category = author.named_categories.build(name: "Primary")
    author.save
    assert Categorization.exists?(author_id: author.id, named_category_name: category.name)
    assert_includes author.named_categories.reload, category
  end

  def test_collection_create_with_nonstandard_primary_key_on_belongs_to
    author   = authors(:mary)
    category = author.named_categories.create(name: "Primary")
    assert Categorization.exists?(author_id: author.id, named_category_name: category.name)
    assert_includes author.named_categories.reload, category
  end

  def test_collection_exists
    author   = authors(:mary)
    category = Category.create!(author_ids: [author.id], name: "Primary")
    assert category.authors.exists?(id: author.id)
    assert category.reload.authors.exists?(id: author.id)
  end

  def test_collection_delete_with_nonstandard_primary_key_on_belongs_to
    author   = authors(:mary)
    category = author.named_categories.create(name: "Primary")
    author.named_categories.delete(category)
    assert !Categorization.exists?(author_id: author.id, named_category_name: category.name)
    assert author.named_categories.reload.empty?
  end

  def test_collection_singular_ids_getter_with_string_primary_keys
    book = books(:awdr)
    assert_equal 2, book.subscriber_ids.size
    assert_equal [subscribers(:first).nick, subscribers(:second).nick].sort, book.subscriber_ids.sort
  end

  def test_collection_singular_ids_setter
    company = companies(:rails_core)
    dev = Developer.first

    company.developer_ids = [dev.id]
    assert_equal [dev], company.developers
  end

  def test_collection_singular_ids_setter_with_string_primary_keys
    assert_nothing_raised do
      book = books(:awdr)
      book.subscriber_ids = [subscribers(:second).nick]
      assert_equal [subscribers(:second)], book.subscribers.reload

      book.subscriber_ids = []
      assert_equal [], book.subscribers.reload
    end

  end

  def test_collection_singular_ids_setter_raises_exception_when_invalid_ids_set
    company = companies(:rails_core)
    ids = [Developer.first.id, -9999]
    assert_raises(ActiveRecord::AssociationTypeMismatch) { company.developer_ids = ids }
  end

  def test_build_a_model_from_hm_through_association_with_where_clause
    assert_nothing_raised { books(:awdr).subscribers.where(nick: "marklazz").build }
  end

  def test_attributes_are_being_set_when_initialized_from_hm_through_association_with_where_clause
    new_subscriber = books(:awdr).subscribers.where(nick: "marklazz").build
    assert_equal new_subscriber.nick, "marklazz"
  end

  def test_attributes_are_being_set_when_initialized_from_hm_through_association_with_multiple_where_clauses
    new_subscriber = books(:awdr).subscribers.where(nick: "marklazz").where(name: "Marcelo Giorgi").build
    assert_equal new_subscriber.nick, "marklazz"
    assert_equal new_subscriber.name, "Marcelo Giorgi"
  end

  def test_include_method_in_association_through_should_return_true_for_instance_added_with_build
    person = Person.new
    reference = person.references.build
    job = reference.build_job
    assert_includes person.jobs, job
  end

  def test_include_method_in_association_through_should_return_true_for_instance_added_with_nested_builds
    author = Author.new
    post = author.posts.build
    comment = post.comments.build
    assert_includes author.comments, comment
  end

  def test_through_association_readonly_should_be_false
    assert !people(:michael).posts.first.readonly?
    assert !people(:michael).posts.to_a.first.readonly?
  end

  def test_can_update_through_association
    assert_nothing_raised do
      people(:michael).posts.first.update!(title: "Can write")
    end
  end

  def test_has_many_through_polymorphic_with_primary_key_option
    assert_equal [categories(:general)], authors(:david).essay_categories

    authors = Author.joins(:essay_categories).where("categories.id" => categories(:general).id)
    assert_equal authors(:david), authors.first

    assert_equal [owners(:blackbeard)], authors(:david).essay_owners

    authors = Author.joins(:essay_owners).where("owners.name = 'blackbeard'")
    assert_equal authors(:david), authors.first
  end

  def test_has_many_through_with_primary_key_option
    assert_equal [categories(:general)], authors(:david).essay_categories_2

    authors = Author.joins(:essay_categories_2).where("categories.id" => categories(:general).id)
    assert_equal authors(:david), authors.first
  end

  def test_size_of_through_association_should_increase_correctly_when_has_many_association_is_added
    post = posts(:thinking)
    readers = post.readers.size
    post.people << people(:michael)
    assert_equal readers + 1, post.readers.size
  end

  def test_has_many_through_with_default_scope_on_join_model
    assert_equal posts(:welcome).comments.order("id").to_a, authors(:david).comments_on_first_posts
  end

  def test_create_has_many_through_with_default_scope_on_join_model
    category = authors(:david).special_categories.create(name: "Foo")
    assert_equal 1, category.categorizations.where(special: true).count
  end

  def test_joining_has_many_through_with_distinct
    mary = Author.joins(:unique_categorized_posts).where(id: authors(:mary).id).first
    assert_equal 1, mary.unique_categorized_posts.length
    assert_equal 1, mary.unique_categorized_post_ids.length
  end

  def test_joining_has_many_through_belongs_to
    posts = Post.joins(:author_categorizations).order("posts.id").
                 where("categorizations.id" => categorizations(:mary_thinking_sti).id)

    assert_equal [posts(:eager_other), posts(:misc_by_mary), posts(:other_by_mary)], posts
  end

  def test_select_chosen_fields_only
    author = authors(:david)
    assert_equal ["body", "id"].sort, author.comments.select("comments.body").first.attributes.keys.sort
  end

  def test_get_has_many_through_belongs_to_ids_with_conditions
    assert_equal [categories(:general).id], authors(:mary).categories_like_general_ids
  end

  def test_get_collection_singular_ids_on_has_many_through_with_conditions_and_include
    person = Person.first
    assert_equal person.posts_with_no_comment_ids, person.posts_with_no_comments.map(&:id)
  end

  def test_count_has_many_through_with_named_scope
    assert_equal 2, authors(:mary).categories.count
    assert_equal 1, authors(:mary).categories.general.count
  end

  def test_has_many_through_belongs_to_should_update_when_the_through_foreign_key_changes
    post = posts(:eager_other)

    post.author_categorizations
    proxy = post.send(:association_instance_get, :author_categorizations)

    assert !proxy.stale_target?
    assert_equal authors(:mary).categorizations.sort_by(&:id), post.author_categorizations.sort_by(&:id)

    post.author_id = authors(:david).id

    assert proxy.stale_target?
    assert_equal authors(:david).categorizations.sort_by(&:id), post.author_categorizations.sort_by(&:id)
  end

  def test_create_with_conditions_hash_on_through_association
    member = members(:groucho)
    club   = member.clubs.create!

    assert_equal true, club.reload.membership.favourite
  end

  def test_deleting_from_has_many_through_a_belongs_to_should_not_try_to_update_counter
    post    = posts(:welcome)
    address = author_addresses(:david_address)

    assert_includes post.author_addresses, address
    post.author_addresses.delete(address)
    assert post[:author_count].nil?
  end

  def test_primary_key_option_on_source
    post     = posts(:welcome)
    category = categories(:general)
    Categorization.create!(post_id: post.id, named_category_name: category.name)

    assert_equal [category], post.named_categories
    assert_equal [category.name], post.named_category_ids # checks when target loaded
    assert_equal [category.name], post.reload.named_category_ids # checks when target no loaded
  end

  def test_create_should_not_raise_exception_when_join_record_has_errors
    repair_validations(Categorization) do
      Categorization.validate { |r| r.errors[:base] << "Invalid Categorization" }
      Category.create(name: "Fishing", authors: [Author.first])
    end
  end

  def test_assign_array_to_new_record_builds_join_records
    c = Category.new(name: "Fishing", authors: [Author.first])
    assert_equal 1, c.categorizations.size
  end

  def test_create_bang_should_raise_exception_when_join_record_has_errors
    repair_validations(Categorization) do
      Categorization.validate { |r| r.errors[:base] << "Invalid Categorization" }
      assert_raises(ActiveRecord::RecordInvalid) do
        Category.create!(name: "Fishing", authors: [Author.first])
      end
    end
  end

  def test_save_bang_should_raise_exception_when_join_record_has_errors
    repair_validations(Categorization) do
      Categorization.validate { |r| r.errors[:base] << "Invalid Categorization" }
      c = Category.new(name: "Fishing", authors: [Author.first])
      assert_raises(ActiveRecord::RecordInvalid) do
        c.save!
      end
    end
  end

  def test_save_returns_falsy_when_join_record_has_errors
    repair_validations(Categorization) do
      Categorization.validate { |r| r.errors[:base] << "Invalid Categorization" }
      c = Category.new(name: "Fishing", authors: [Author.first])
      assert_not c.save
    end
  end

  def test_preloading_empty_through_association_via_joins
    person = Person.create!(first_name: "Gaga")
    person = Person.where(id: person.id).where("readers.id = 1 or 1=1").references(:readers).includes(:posts).to_a.first

    assert person.posts.loaded?, "person.posts should be loaded"
    assert_equal [], person.posts
  end

  def test_preloading_empty_through_with_polymorphic_source_association
    owner = Owner.create!(name: "Rainbow Unicat")
    pet = Pet.create!(owner: owner)
    person = Person.create!(first_name: "Gaga")
    treasure = Treasure.create!(looter: person)
    non_looted_treasure = Treasure.create!()
    PetTreasure.create!(pet: pet, treasure: treasure, rainbow_color: "Ultra violet indigo")
    PetTreasure.create!(pet: pet, treasure: non_looted_treasure, rainbow_color: "Ultra violet indigo")

    assert_equal [person], Owner.where(name: "Rainbow Unicat").includes(pets: :persons).first.persons.to_a
  end

  def test_explicitly_joining_join_table
    assert_equal owners(:blackbeard).toys, owners(:blackbeard).toys.with_pet
  end

  def test_has_many_through_with_polymorphic_source
    post = tags(:general).tagged_posts.create! title: "foo", body: "bar"
    assert_equal [tags(:general)], post.reload.tags
  end

  def test_has_many_through_obeys_order_on_through_association
    owner = owners(:blackbeard)
    assert_includes owner.toys.to_sql, "pets.name desc"
    assert_equal ["parrot", "bulbul"], owner.toys.map { |r| r.pet.name }
  end

  def test_has_many_through_associations_on_new_records_use_null_relations
    person = Person.new

    assert_no_queries(ignore_none: false) do
      assert_equal [], person.posts
      assert_equal [], person.posts.where(body: "omg")
      assert_equal [], person.posts.pluck(:body)
      assert_equal 0,  person.posts.sum(:tags_count)
      assert_equal 0,  person.posts.count
    end
  end

  def test_has_many_through_with_default_scope_on_the_target
    person = people(:michael)
    assert_equal [posts(:thinking).id], person.first_posts.map(&:id)

    readers(:michael_authorless).update(first_post_id: 1)
    assert_equal [posts(:thinking).id], person.reload.first_posts.map(&:id)
  end

  def test_has_many_through_with_includes_in_through_association_scope
    assert_not_empty posts(:welcome).author_address_extra_with_address
  end

  def test_insert_records_via_has_many_through_association_with_scope
    club = Club.create!
    member = Member.create!
    Membership.create!(club: club, member: member)

    club.favourites << member
    assert_equal [member], club.favourites

    club.reload
    assert_equal [member], club.favourites
  end

  def test_has_many_through_unscope_default_scope
    post = Post.create!(title: "Beaches", body: "I like beaches!")
    Reader.create! person: people(:david), post: post
    LazyReader.create! person: people(:susan), post: post

    assert_equal 2, post.people.to_a.size
    assert_equal 1, post.lazy_people.to_a.size

    assert_equal 2, post.lazy_readers_unscope_skimmers.to_a.size
    assert_equal 2, post.lazy_people_unscope_skimmers.to_a.size
  end

  def test_has_many_through_add_with_sti_middle_relation
    club = SuperClub.create!(name: "Fight Club")
    member = Member.create!(name: "Tyler Durden")

    club.members << member
    assert_equal 1, SuperMembership.where(member_id: member.id, club_id: club.id).count
  end

  def test_build_for_has_many_through_association
    organization = organizations(:nsa)
    author = organization.author
    post_direct = author.posts.build
    post_through = organization.posts.build
    assert_equal post_direct.author_id, post_through.author_id
  end

  def test_has_many_through_with_scope_that_should_not_be_fully_merged
    Club.has_many :distinct_memberships, -> { distinct }, class_name: "Membership"
    Club.has_many :special_favourites, through: :distinct_memberships, source: :member

    assert_nil Club.new.special_favourites.distinct_value
  end

  def test_association_force_reload_with_only_true_is_deprecated
    post = Post.find(1)

    assert_deprecated { post.people(true) }
  end

  def test_has_many_through_do_not_cache_association_reader_if_the_though_method_has_default_scopes
    member = Member.create!
    club = Club.create!
    TenantMembership.create!(
      member: member,
      club: club
    )

    TenantMembership.current_member = member

    tenant_clubs = member.tenant_clubs
    assert_equal [club], tenant_clubs

    TenantMembership.current_member = nil

    other_member = Member.create!
    other_club = Club.create!
    TenantMembership.create!(
      member: other_member,
      club: other_club
    )

    tenant_clubs = other_member.tenant_clubs
    assert_equal [other_club], tenant_clubs
  ensure
    TenantMembership.current_member = nil
  end
end

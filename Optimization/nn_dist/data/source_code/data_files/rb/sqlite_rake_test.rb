require "cases/helper"
require "active_record/tasks/database_tasks"
require "pathname"

if current_adapter?(:SQLite3Adapter)
  module ActiveRecord
    class SqliteDBCreateTest < ActiveRecord::TestCase
      def setup
        @database      = "db_create.sqlite3"
        @connection    = stub :connection
        @configuration = {
          "adapter"  => "sqlite3",
          "database" => @database
        }

        File.stubs(:exist?).returns(false)
        ActiveRecord::Base.stubs(:connection).returns(@connection)
        ActiveRecord::Base.stubs(:establish_connection).returns(true)

        $stdout, @original_stdout = StringIO.new, $stdout
        $stderr, @original_stderr = StringIO.new, $stderr
      end

      def teardown
        $stdout, $stderr = @original_stdout, @original_stderr
      end

      def test_db_checks_database_exists
        File.expects(:exist?).with(@database).returns(false)

        ActiveRecord::Tasks::DatabaseTasks.create @configuration, "/rails/root"
      end

      def test_when_db_created_successfully_outputs_info_to_stdout
        ActiveRecord::Tasks::DatabaseTasks.create @configuration, "/rails/root"

        assert_equal $stdout.string, "Created database '#{@database}'\n"
      end

      def test_db_create_when_file_exists
        File.stubs(:exist?).returns(true)

        ActiveRecord::Tasks::DatabaseTasks.create @configuration, "/rails/root"

        assert_equal $stderr.string, "Database '#{@database}' already exists\n"
      end

      def test_db_create_with_file_does_nothing
        File.stubs(:exist?).returns(true)
        $stderr.stubs(:puts).returns(nil)

        ActiveRecord::Base.expects(:establish_connection).never

        ActiveRecord::Tasks::DatabaseTasks.create @configuration, "/rails/root"
      end

      def test_db_create_establishes_a_connection
        ActiveRecord::Base.expects(:establish_connection).with(@configuration)

        ActiveRecord::Tasks::DatabaseTasks.create @configuration, "/rails/root"
      end

      def test_db_create_with_error_prints_message
        ActiveRecord::Base.stubs(:establish_connection).raises(Exception)

        $stderr.stubs(:puts).returns(true)
        $stderr.expects(:puts).
          with("Couldn't create database for #{@configuration.inspect}")

        assert_raises(Exception) { ActiveRecord::Tasks::DatabaseTasks.create @configuration, "/rails/root" }
      end
    end

    class SqliteDBDropTest < ActiveRecord::TestCase
      def setup
        @database      = "db_create.sqlite3"
        @path          = stub(to_s: "/absolute/path", absolute?: true)
        @configuration = {
          "adapter"  => "sqlite3",
          "database" => @database
        }

        Pathname.stubs(:new).returns(@path)
        File.stubs(:join).returns("/former/relative/path")
        FileUtils.stubs(:rm).returns(true)

        $stdout, @original_stdout = StringIO.new, $stdout
        $stderr, @original_stderr = StringIO.new, $stderr
      end

      def teardown
        $stdout, $stderr = @original_stdout, @original_stderr
      end

      def test_creates_path_from_database
        Pathname.expects(:new).with(@database).returns(@path)

        ActiveRecord::Tasks::DatabaseTasks.drop @configuration, "/rails/root"
      end

      def test_removes_file_with_absolute_path
        File.stubs(:exist?).returns(true)
        @path.stubs(:absolute?).returns(true)

        FileUtils.expects(:rm).with("/absolute/path")

        ActiveRecord::Tasks::DatabaseTasks.drop @configuration, "/rails/root"
      end

      def test_generates_absolute_path_with_given_root
        @path.stubs(:absolute?).returns(false)

        File.expects(:join).with("/rails/root", @path).
          returns("/former/relative/path")

        ActiveRecord::Tasks::DatabaseTasks.drop @configuration, "/rails/root"
      end

      def test_removes_file_with_relative_path
        File.stubs(:exist?).returns(true)
        @path.stubs(:absolute?).returns(false)

        FileUtils.expects(:rm).with("/former/relative/path")

        ActiveRecord::Tasks::DatabaseTasks.drop @configuration, "/rails/root"
      end

      def test_when_db_dropped_successfully_outputs_info_to_stdout
        ActiveRecord::Tasks::DatabaseTasks.drop @configuration, "/rails/root"

        assert_equal $stdout.string, "Dropped database '#{@database}'\n"
      end
    end

    class SqliteDBCharsetTest < ActiveRecord::TestCase
      def setup
        @database      = "db_create.sqlite3"
        @connection    = stub :connection
        @configuration = {
          "adapter"  => "sqlite3",
          "database" => @database
        }

        File.stubs(:exist?).returns(false)
        ActiveRecord::Base.stubs(:connection).returns(@connection)
        ActiveRecord::Base.stubs(:establish_connection).returns(true)
      end

      def test_db_retrieves_charset
        @connection.expects(:encoding)
        ActiveRecord::Tasks::DatabaseTasks.charset @configuration, "/rails/root"
      end
    end

    class SqliteDBCollationTest < ActiveRecord::TestCase
      def setup
        @database      = "db_create.sqlite3"
        @connection    = stub :connection
        @configuration = {
          "adapter"  => "sqlite3",
          "database" => @database
        }

        File.stubs(:exist?).returns(false)
        ActiveRecord::Base.stubs(:connection).returns(@connection)
        ActiveRecord::Base.stubs(:establish_connection).returns(true)
      end

      def test_db_retrieves_collation
        assert_raise NoMethodError do
          ActiveRecord::Tasks::DatabaseTasks.collation @configuration, "/rails/root"
        end
      end
    end

    class SqliteStructureDumpTest < ActiveRecord::TestCase
      def setup
        @database      = "db_create.sqlite3"
        @configuration = {
          "adapter"  => "sqlite3",
          "database" => @database
        }
      end

      def test_structure_dump
        dbfile   = @database
        filename = "awesome-file.sql"

        ActiveRecord::Tasks::DatabaseTasks.structure_dump @configuration, filename, "/rails/root"
        assert File.exist?(dbfile)
        assert File.exist?(filename)
      ensure
        FileUtils.rm_f(filename)
        FileUtils.rm_f(dbfile)
      end
    end

    class SqliteStructureLoadTest < ActiveRecord::TestCase
      def setup
        @database      = "db_create.sqlite3"
        @configuration = {
          "adapter"  => "sqlite3",
          "database" => @database
        }
      end

      def test_structure_load
        dbfile   = @database
        filename = "awesome-file.sql"

        open(filename, "w") { |f| f.puts("select datetime('now', 'localtime');") }
        ActiveRecord::Tasks::DatabaseTasks.structure_load @configuration, filename, "/rails/root"
        assert File.exist?(dbfile)
      ensure
        FileUtils.rm_f(filename)
        FileUtils.rm_f(dbfile)
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/herb/dev/server_entry"

module Dev
  class ServerEntryTest < Minitest::Spec
    def with_entry(port:, project:, pid: Process.pid)
      entry = Herb::Dev::ServerEntry.new(pid: pid, port: port, project: project)
      entry.save

      yield entry
    ensure
      entry&.remove
    end

    test "find_by_project matches an exact path" do
      project = File.realpath(Dir.pwd)

      with_entry(port: 8701, project: project) do
        assert_equal 8701, Herb::Dev::ServerEntry.find_by_project(project)&.port
      end
    end

    test "find_by_project matches a path with a trailing slash" do
      project = File.realpath(Dir.pwd)

      with_entry(port: 8702, project: project) do
        assert_equal 8702, Herb::Dev::ServerEntry.find_by_project("#{project}/")&.port
      end
    end

    test "find_by_project does not match an unrelated project" do
      with_entry(port: 8703, project: File.realpath(Dir.pwd)) do
        assert_nil Herb::Dev::ServerEntry.find_by_project("/nonexistent/other-project")
      end
    end

    test "find_by_project ignores entries whose process is gone" do
      project = File.realpath(Dir.pwd)

      with_entry(port: 8704, project: project, pid: 999_999) do
        assert_nil Herb::Dev::ServerEntry.find_by_project(project)
      end
    end

    test "find_by_project returns nil when given nil" do
      assert_nil Herb::Dev::ServerEntry.find_by_project(nil)
    end

    test "resolve_path returns nil for a path that does not exist" do
      assert_nil Herb::Dev::ServerEntry.resolve_path("/nonexistent/path")
    end

    test "Herb.dev_server_port reports the port for a running project" do
      project = File.realpath(Dir.pwd)

      with_entry(port: 8705, project: project) do
        assert_equal 8705, Herb.dev_server_port(project)
      end
    end

    test "Herb.dev_server_port returns nil when no server runs for the project" do
      assert_nil Herb.dev_server_port("/nonexistent/other-project")
    end
  end
end

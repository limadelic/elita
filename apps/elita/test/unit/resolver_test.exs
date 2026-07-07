defmodule ResolverUnitTest do
  use ExUnit.Case

  describe "bare name resolution" do
    test "unique name" do
      world = [%{name: "doc", path: "/work/dev", kind: :file}]
      assert {:ok, %{name: "doc", path: "/work/dev", kind: :file}} = Resolver.resolve("doc", world, "/")
    end

    test "ambiguous names" do
      world = [
        %{name: "doc", path: "/work/dev", kind: :file},
        %{name: "doc", path: "/home/user", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("doc", world, "/")
      assert length(entries) == 2
    end

    test "unknown name" do
      world = [%{name: "doc", path: "/work/dev", kind: :file}]
      assert {:error, :unknown} = Resolver.resolve("missing", world, "/")
    end
  end

  describe "file beats folder precedence" do
    test "file beats folder at same location" do
      world = [
        %{name: "doc", path: "/work", kind: :folder},
        %{name: "doc", path: "/work", kind: :file}
      ]
      {:ok, entry} = Resolver.resolve("doc", world, "/")
      assert entry.kind == :file
    end
  end

  describe "absolute path resolution" do
    test "name at absolute path" do
      world = [
        %{name: "doc", path: "/work/dev", kind: :file},
        %{name: "doc", path: "/home", kind: :file}
      ]
      assert {:ok, %{path: "/work/dev"}} = Resolver.resolve("doc@/work/dev", world, "/")
    end

    test "unknown at absolute path" do
      world = [%{name: "doc", path: "/work", kind: :file}]
      assert {:error, :unknown} = Resolver.resolve("doc@/home", world, "/")
    end

    test "fanout at absolute path" do
      world = [
        %{name: "a", path: "/work", kind: :file},
        %{name: "b", path: "/work", kind: :file},
        %{name: "c", path: "/home", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("@/work", world, "/")
      assert length(entries) == 2
    end
  end

  describe "relative path resolution" do
    test "name at relative path resolved against cwd" do
      world = [
        %{name: "doc", path: "/home/user/work", kind: :file},
        %{name: "doc", path: "/work", kind: :file}
      ]
      assert {:ok, %{path: "/home/user/work"}} = Resolver.resolve("doc@work", world, "/home/user")
    end

    test "relative path with multiple segments" do
      world = [%{name: "test", path: "/home/user/projects/web", kind: :file}]
      assert {:ok, %{path: "/home/user/projects/web"}} = Resolver.resolve("test@projects/web", world, "/home/user")
    end
  end

  describe "glob patterns" do
    test "single segment glob with *" do
      world = [
        %{name: "doc", path: "/work/dev/rec", kind: :file},
        %{name: "doc", path: "/work/prod/rec", kind: :file},
        %{name: "doc", path: "/home/dev/rec", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("doc@/work/*/rec", world, "/")
      assert length(entries) == 2
    end

    test "any depth glob with **" do
      world = [
        %{name: "doctor", path: "/work/dev/rec", kind: :file},
        %{name: "doctor", path: "/work/prod/services/rec", kind: :file},
        %{name: "doctor", path: "/home/work", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("doctor@/work/**", world, "/")
      assert length(entries) == 2
    end

    test "fanout with glob pattern" do
      world = [
        %{name: "a", path: "/work/services/dev", kind: :file},
        %{name: "b", path: "/work/apps/dev", kind: :file},
        %{name: "c", path: "/work/prod", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("@*/dev", world, "/work")
      assert length(entries) == 2
    end

    test "glob pattern relative to cwd" do
      world = [
        %{name: "test", path: "/home/user/proj1/src", kind: :file},
        %{name: "test", path: "/home/user/proj2/src", kind: :file},
        %{name: "other", path: "/home/user/proj1/src", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("test@*/src", world, "/home/user")
      assert length(entries) == 2
    end
  end

  describe "complex scenarios" do
    test "bare name in deep tree" do
      world = [
        %{name: "config", path: "/work/deep/nested/folder", kind: :file},
        %{name: "other", path: "/work/deep", kind: :file}
      ]
      assert {:ok, %{name: "config"}} = Resolver.resolve("config", world, "/")
    end

    test "multiple matches with globs" do
      world = [
        %{name: "app", path: "/work/dev/frontend", kind: :folder},
        %{name: "app", path: "/work/prod/frontend", kind: :folder},
        %{name: "app", path: "/work/staging/frontend", kind: :folder}
      ]
      assert {:many, entries} = Resolver.resolve("app@/work/*/frontend", world, "/")
      assert length(entries) == 3
    end
  end
end

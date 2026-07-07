defmodule ResolverUnitTest do
  use ExUnit.Case

  describe "return values" do
    test "zero matches returns error" do
      world = [%{name: "doc", path: "/work/dev", kind: :file}]
      assert {:error, :unknown} = Resolver.resolve("missing", world, "/")
    end

    test "one match returns ok" do
      world = [%{name: "doc", path: "/work/dev", kind: :file}]
      assert {:ok, %{name: "doc"}} = Resolver.resolve("doc", world, "/")
    end

    test "many matches returns many" do
      world = [
        %{name: "doc", path: "/work/dev", kind: :file},
        %{name: "doc", path: "/home/user", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("doc", world, "/")
      assert length(entries) == 2
    end
  end

  describe "file beats folder" do
    test "file wins at same location" do
      world = [
        %{name: "doc", path: "/work", kind: :folder},
        %{name: "doc", path: "/work", kind: :file}
      ]
      {:ok, entry} = Resolver.resolve("doc", world, "/")
      assert entry.kind == :file
    end
  end

  describe "globs" do
    test "single segment * matches one path segment" do
      world = [
        %{name: "doc", path: "/work/dev/rec", kind: :file},
        %{name: "doc", path: "/work/prod/rec", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("doc@/work/*/rec", world, "/")
      assert length(entries) == 2
    end

    test "** matches any depth" do
      world = [
        %{name: "doctor", path: "/work/dev/rec", kind: :file},
        %{name: "doctor", path: "/work/prod/services/rec", kind: :file},
        %{name: "other", path: "/home/work", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("doctor@/work/**", world, "/")
      assert length(entries) == 2
    end

    test "** at end matches zero segments (exact path)" do
      world = [
        %{name: "x", path: "/a", kind: :file},
        %{name: "x", path: "/a/b", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("x@/a/**", world, "/")
      assert length(entries) == 2
    end

    test "** at start matches zero segments at root" do
      world = [
        %{name: "x", path: "/x", kind: :file},
        %{name: "x", path: "/a/x", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("x@/**/x", world, "/")
      assert length(entries) == 2
    end

    test "bare ** matches all paths" do
      world = [
        %{name: "doc", path: "/a/b", kind: :file},
        %{name: "doc", path: "/x/y/z", kind: :file}
      ]
      assert {:many, entries} = Resolver.resolve("doc@/**", world, "/")
      assert length(entries) == 2
    end
  end
end

defmodule Absinthe.SchemaTest do
  use ExSpec, async: true
  use SupportSchemas

  alias Absinthe.Schema
  alias Absinthe.Type

  describe "built-in types" do

    def load_valid_schema do
      load_schema("valid_schema")
    end

    it "are loaded" do
      load_valid_schema
      assert map_size(Absinthe.Type.BuiltIns.__absinthe_types__) > 0
      Absinthe.Type.BuiltIns.__absinthe_types__
      |> Enum.each(fn
        {ident, name} ->
          assert ValidSchema.__absinthe_type__(ident) == ValidSchema.__absinthe_type__(name)
      end)
      int = ValidSchema.__absinthe_type__(:integer)
      assert 1 == Type.Scalar.serialize(int, 1)
      assert {:ok, 1} == Type.Scalar.parse(int, "1.0")
    end

  end

  describe "using the same identifier" do

    it "raises an exception" do
      assert_schema_error("schema_with_duplicate_identifiers",
                          [%{rule: Absinthe.Schema.Rule.TypeNamesAreUnique, data: %{artifact: "Absinthe type identifier", value: :person}}])
    end

  end

  describe "using the same name" do

    def load_duplicate_name_schema do
      load_schema("schema_with_duplicate_names")
    end

    it "raises an exception" do
      assert_schema_error("schema_with_duplicate_names",
                          [%{rule: Absinthe.Schema.Rule.TypeNamesAreUnique, data: %{artifact: "Type name", value: "Person"}}])
    end

  end

  defmodule SourceSchema do
    use Absinthe.Schema

    query [
      fields: [
        foo: [
          type: :foo,
          resolve: fn
            _, _ -> {:ok, %{name: "Fancy Foo!"}}
          end
        ]
      ]
    ]

    object :foo, [
      fields: [
        name: [type: :string]
      ]
    ]

  end

  defmodule UserSchema do
    use Absinthe.Schema

    import_types SourceSchema

    query [
      fields: [
        foo: [
          type: :foo,
          resolve: fn
            _, _ -> {:ok, %{name: "A different fancy Foo!"}}
          end
        ],
        bar: [
          type: :bar,
          resolve: fn
            _, _ -> {:ok, %{name: "A plain old bar"}}
          end
        ]
      ]
    ]

    object :bar, [
      fields: [
        name: [type: :string]
      ]
    ]

  end

  defmodule ThirdSchema do
    use Absinthe.Schema

    import_types UserSchema

    object :baz, [
      fields: [
        name: [type: :string]
      ]
    ]

  end


  describe "using import_types" do

    it "adds the types from a parent" do
      assert %{foo: "Foo", bar: "Bar"} = UserSchema.__absinthe_types__
      assert "Foo" == UserSchema.__absinthe_type__(:foo).name
    end

    it "adds the types from a grandparent" do
      assert %{foo: "Foo", bar: "Bar", baz: "Baz"} = ThirdSchema.__absinthe_types__
      assert "Foo" == ThirdSchema.__absinthe_type__(:foo).name
    end

  end

  describe "lookup_type" do

    it "is supported" do
      assert "Foo" == Schema.lookup_type(ThirdSchema, :foo).name
    end

  end

  defmodule RootsSchema do
    use Absinthe.Schema

    import_types SourceSchema

    query [
      fields: [
        name: [
          type: :string,
          args: [
            family_name: [type: :boolean]
          ]
        ]
      ]
    ]

    mutation "MyRootMutation", [
      fields: [
        name: [type: :string]
      ]
    ]
  end


  describe "root fields" do

    it "can have a default name" do
      assert "RootQueryType" == Schema.lookup_type(RootsSchema, :query).name
    end

    it "can have a custom name" do
      assert "MyRootMutation" == Schema.lookup_type(RootsSchema, :mutation).name
    end

  end

  describe "fields" do

    it "have the correct structure" do
      assert %Type.Field{name: "name"} = Schema.lookup_type(RootsSchema, :query).fields.name
    end

  end

  describe "arguments" do

    it "have the correct structure" do
      assert %Type.Argument{name: "family_name"} = Schema.lookup_type(RootsSchema, :query).fields.name.args.family_name
    end

  end

end

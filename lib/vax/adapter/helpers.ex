defmodule Vax.Adapter.Helpers do
  @moduledoc false
  # TODO: split by purpose (?)

  @spec schema_primary_key!(schema :: atom()) :: atom()
  def schema_primary_key!(schema) do
    case schema.__schema__(:primary_key) do
      [primary_key] ->
        primary_key

      [] ->
        raise "Vax requires all schemas to have a primary key, found none for schema #{schema}"

      keys ->
        raise "Vax requires all schemas to have no more than one primary key. Found #{keys} for schema #{schema}"
    end
  end

  @spec object_key(schema_source :: binary(), primary_key :: binary()) :: binary()
  def object_key(schema_source, primary_key) do
    schema_source <> ":" <> primary_key
  end

  @spec build_object(schema_source :: binary(), primary_key :: binary(), bucket :: binary()) ::
          {binary(), :antidote_crdt_map_rr, binary()}
  def build_object(schema_source, primary_key, bucket) do
    {object_key(schema_source, primary_key), :antidote_crdt_map_rr, bucket}
  end

  @spec load_map(
          repo :: atom(),
          schema :: Ecto.Schema.t(),
          antidote_map :: :antidotec_map.antidotec_map()
        ) :: struct() | nil
  def load_map(repo, schema, map) do
    map
    |> Enum.map(fn {{k, _t}, v} -> {String.to_atom(k), v} end)
    |> case do
      [] -> nil
      fields -> repo.load(schema, fields)
    end
  end

  @spec build_insert_map(repo :: atom(), schema :: Ecto.Schema.t()) ::
          :antidotec_map.antidote_map()
  def build_insert_map(_repo, schema) do
    schema_types = schema_types(schema)

    schema
    |> Map.from_struct()
    |> Map.drop([:__meta__, :__struct__])
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.reduce(:antidotec_map.new(), fn {field, value}, map ->
      update_map_value(map, schema_types, field, value, schema.__struct__)
    end)
  end

  def build_update_map(_repo, schema, changeset) do
    schema_types = schema_types(schema)
    map = to_antidotec_map(schema, schema_types)

    Enum.reduce(changeset.changes, map, fn {field, new_value}, map ->
      update_map_value(map, schema_types, field, new_value, schema.__struct__)
    end)
  end

  defp update_map_value(map, schema_types, field, new_value, schema) do
    field_type = schema_types[field]
    # todo: (?)
    field_default = schema |> struct() |> Map.get(field)

    antidotec_value = get_antidote_map_field_or_default(map, field, field_type, field_default)
    map_key = {Atom.to_string(field), Vax.Type.crdt_type(field_type)}
    value = Vax.Type.compute_change(field_type, antidotec_value, new_value)
    :antidotec_map.add_or_update(map, map_key, value)
  end

  def get_antidote_map_field_or_default(map, field, field_type, field_default) do
    map
    |> elem(1)
    |> Enum.find(fn {{key, _type}, _value} -> key == field end)
    |> case do
      nil ->
        Vax.Type.client_dump(field_type, field_default)

      {{_key, _type}, value} ->
        value
    end
  end

  defp schema_types(%schema_mod{} = _schema) do
    schema_mod.__schema__(:fields)
    |> Map.new(fn field ->
      {field, schema_mod.__schema__(:type, field)}
    end)
  end

  defp to_antidotec_map(schema, schema_types) do
    crdt_types = Map.new(schema_types, fn {key, type} -> {key, Vax.Type.crdt_type(type)} end)

    # TODO: maybe hook a better interface in antidote client
    map = :antidotec_map.new()

    map_values =
      schema
      |> Map.from_struct()
      |> Map.drop([:__struct__, :__meta__])
      |> Map.new(fn {key, value} ->
        {{key, crdt_types[key]}, Vax.Type.client_dump(schema_types[key], value)}
      end)

    {elem(map, 0), map_values, elem(map, 2), elem(map, 3)}
  end
end

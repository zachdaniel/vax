defmodule Vax.Adapter do
  @moduledoc """
  Ecto adapter for Vaxine
  """

  alias Vax.ConnectionPool
  alias Vax.Adapter.Helpers

  @behaviour Ecto.Adapter
  @behaviour Ecto.Adapter.Schema

  @bucket "vax"

  @impl Ecto.Adapter
  def loaders(:binary_id, type), do: [Ecto.UUID, type]
  def loaders(:string, :string), do: [:string]
  def loaders(_primitive_type, ecto_type), do: [&binary_to_term/1, ecto_type]

  @impl Ecto.Adapter
  def dumpers(:binary_id, type), do: [type, Ecto.UUID]
  def dumpers(:string, :string), do: [:string]
  def dumpers(_primitive_type, ecto_type), do: [ecto_type, &term_to_binary/1]

  defp term_to_binary(term), do: {:ok, :erlang.term_to_binary(term)}
  defp binary_to_term(binary), do: {:ok, :erlang.binary_to_term(binary)}

  @impl Ecto.Adapter
  def init(config) do
    address = Keyword.fetch!(config, :address) |> String.to_charlist()
    port = Keyword.get(config, :port, 8087)
    pool_size = Keyword.get(config, :pool_size, 10)

    child_spec = %{
      id: ConnectionPool,
      start:
        {NimblePool, :start_link,
         [[worker: {ConnectionPool, [address: address, port: port]}, size: pool_size]]}
    }

    {:ok, child_spec, %{}}
  end

  @impl Ecto.Adapter
  def ensure_all_started(_config, _type) do
    {:ok, []}
  end

  @impl Ecto.Adapter
  def checkout(%{pid: pool}, _config, function) do
    if Process.get(:vax_checked_out_conn) do
      function.()
    else
      ConnectionPool.checkout(pool, fn {_pid, _ref}, pid ->
        try do
          Process.put(:vax_checked_out_conn, pid)
          result = function.()

          {result, pid}
        after
          Process.put(:vax_checked_out_conn, nil)
        end
      end)
    end
  end

  @impl Ecto.Adapter
  def checked_out?(_adapter_meta) do
    not is_nil(Process.get(:vax_checked_out_conn))
  end

  @impl Ecto.Adapter
  defmacro __before_compile__(_env) do
    quote do
      @impl Ecto.Repo
      def get(schema, id, opts \\ []) do
        Vax.Adapter.get(__MODULE__, schema, id, opts)
      end

      @doc """
      Increments a counter

      See `Vax.Adapter.increment_counter/3` for more information
      """
      @spec increment_counter(key :: binary(), amount :: integer()) :: :ok
      def increment_counter(key, amount) do
        Vax.Adapter.increment_counter(__MODULE__, key, amount)
      end

      @doc """
      Reads a counter

      See `Vax.Adapter.read_counter/2` for more information
      """
      @spec read_counter(key :: binary()) :: integer()
      def read_counter(key) do
        Vax.Adapter.read_counter(__MODULE__, key)
      end

      @doc """
      Executes a static transaction
      """
      @spec execute_static_transaction((conn :: pid(), tx_id :: term() -> result :: term())) ::
              term()
      def execute_static_transaction(fun) do
        Vax.Adapter.execute_static_transaction(__MODULE__, fun)
      end
    end
  end

  def get(repo, schema, pk, _opts) do
    execute_static_transaction(repo, fn conn, tx_id ->
      pk = Ecto.UUID.dump!(pk)
      object = Helpers.build_object(schema.__schema__(:source), pk, @bucket)

      {:ok, [result]} = :antidotec_pb.read_objects(conn, [object], tx_id)

      Helpers.load_map(repo, schema, result)
    end)
  end

  @doc """
  Reads a counter
  """
  @spec read_counter(repo :: atom() | pid(), key :: binary()) :: integer()
  def read_counter(repo, key) do
    execute_static_transaction(repo, fn conn, tx_id ->
      obj = {key, :antidote_crdt_counter_pn, @bucket}
      {:ok, [result]} = :antidotec_pb.read_objects(conn, [obj], tx_id)

      :antidotec_counter.value(result)
    end)
  end

  @doc """
  Increases a counter
  """
  @spec increment_counter(repo :: atom() | pid(), key :: binary(), amount :: integer()) :: :ok
  def increment_counter(repo, key, amount) do
    execute_static_transaction(repo, fn conn, tx_id ->
      obj = {key, :antidote_crdt_counter_pn, @bucket}
      counter = :antidotec_counter.increment(amount, :antidotec_counter.new())
      counter_update_ops = :antidotec_counter.to_ops(obj, counter)

      :antidotec_pb.update_objects(conn, counter_update_ops, tx_id)
    end)
  end

  @impl Ecto.Adapter.Schema
  def autogenerate(_type), do: Ecto.UUID.generate() |> Ecto.UUID.dump!()

  @impl Ecto.Adapter.Schema
  def delete(adapter_meta, schema_meta, filters, _options) do
    execute_static_transaction(adapter_meta, fn conn, tx_id ->
      schema_primary_key = Helpers.schema_primary_key!(schema_meta.schema)
      primary_key = Keyword.get(filters, schema_primary_key)
      object = Helpers.build_object(schema_meta.source, primary_key, @bucket)

      :ok = :antidotec_pb.update_objects(conn, [{object, :reset, {}}], tx_id)

      {:ok, []}
    end)
  end

  @impl Ecto.Adapter.Schema
  def insert(adapter_meta, schema_meta, fields, _on_conflict, _returning, _options) do
    execute_static_transaction(adapter_meta, fn conn, tx_id ->
      schema_primary_key = Helpers.schema_primary_key!(schema_meta.schema)

      primary_key =
        Keyword.get_lazy(fields, schema_primary_key, fn ->
          Ecto.UUID.generate() |> Ecto.UUID.dump!()
        end)

      object = Helpers.build_object(schema_meta.source, primary_key, @bucket)
      map = Helpers.build_update_map(adapter_meta.repo, schema_meta.schema, fields)

      ops = :antidotec_map.to_ops(object, map)
      :ok = :antidotec_pb.update_objects(conn, ops, tx_id)

      {:ok, []}
    end)
  end

  @impl Ecto.Adapter.Schema
  def insert_all(
        _adapter_meta,
        _schema_meta,
        _header,
        _list,
        _on_conflict,
        _returning,
        _placeholders,
        _options
      ) do
    raise "Not implemented"
  end

  @impl Ecto.Adapter.Schema
  def update(adapter_meta, schema_meta, fields, filters, _returning, _options) do
    execute_static_transaction(adapter_meta, fn conn, tx_id ->
      schema_primary_key = Helpers.schema_primary_key!(schema_meta.schema)
      primary_key = Keyword.get(filters, schema_primary_key)
      object = Helpers.build_object(schema_meta.source, primary_key, @bucket)

      map = Helpers.build_update_map(adapter_meta.repo, schema_meta.schema, fields)

      ops = :antidotec_map.to_ops(object, map)
      :ok = :antidotec_pb.update_objects(conn, ops, tx_id)

      {:ok, []}
    end)
  end

  defp get_conn(), do: Process.get(:vax_checked_out_conn) || raise("Missing connection")

  def execute_static_transaction(repo, fun) when is_atom(repo) or is_pid(repo) do
    meta = Ecto.Adapter.lookup_meta(repo)
    execute_static_transaction(meta, fun)
  end

  def execute_static_transaction(meta, fun) do
    checkout(meta, [], fn ->
      conn = get_conn()

      {:ok, tx_id} = :antidotec_pb.start_transaction(conn, :ignore, static: true)

      fun.(conn, tx_id)
    end)
  end
end
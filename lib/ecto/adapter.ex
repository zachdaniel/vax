defmodule Vax.Ecto.Adapter do
  @moduledoc """
  Vaxine adapter for Ecto.
  """

  alias Vax.Ecto.Types

  @behaviour Ecto.Adapter

  # @behaviour Ecto.Adapter.Query
  # @behaviour Ecto.Adapter.Schema
  # @behaviour Ecto.Adapter.Storage
  # @behaviour Ecto.Adapter.Transaction

  @default_hostname "localhost"
  @default_port 8087

  @impl Ecto.Adapter
  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Fetches a struct using the given primary key `id`.

      On success, will return the struct.
      On failure (if the struct does not exist within the Riak database), returns `nil`.

      """
      def get(schema_module, id, opts \\ []) do
        {adapter, meta} = Ecto.Repo.Registry.lookup(__MODULE__)
        adapter.get(__MODULE__, meta, schema_module, id, opts)
      end

      @doc """
      Inserts (or updates) a struct in the database.
      Pass either a struct or an `Ecto.Changeset`

      On success, will return `{:ok, struct}`.
      On failure (when there were validation problems for instance), will return `{:error, struct_or_changeset}`
      """
      def insert(struct_or_changeset, opts \\ []) do
        {adapter, meta} = Ecto.Repo.Registry.lookup(__MODULE__)
        adapter.insert(__MODULE__, meta, struct_or_changeset, opts)
      end

      @doc """
      Deletes a struct from the database, using the primary ID of the struct or changeset
      passed to this function.

      Returns `{:ok, struct}` on success.
      Raises `Ecto.NoPrimaryKeyValueError` if the passed struct or changeset does not have a primary key set.
      """
      def delete(struct_or_changeset, opts \\ []) do
        {adapter, meta} = Ecto.Repo.Registry.lookup(__MODULE__)
        adapter.delete(__MODULE__, meta, struct_or_changeset, opts)
      end
    end
  end

  @impl Ecto.Adapter
  def checkout(adapter_meta, config, fun) do
    IO.inspect {
      :checkout,
      adapter_meta,
      config
    }

    fun.()
  end

  @impl Ecto.Adapter
  def checked_out?(adapter_meta) do
    IO.inspect {
      :checked_out?,
      adapter_meta
    }

    throw :NotImplemented
  end

  @impl Ecto.Adapter
  def dumpers(primitive_type, ecto_type)
  def dumpers(:binary_id, type), do: [&Types.String.dump/1, type]
  def dumpers(:embed_id, type), do: [&Types.String.dump/1, type]
  def dumpers(:string, type), do: [&Types.String.dump/1, type]
  def dumpers(_primitive, type), do: [type]

  @impl Ecto.Adapter
  def loaders(primitive_type, ecto_type)
  def loaders(:binary_id, type), do: [&Types.String.load/1, type]
  def loaders(:embed_id, type), do: [&Types.String.load/1, type]
  def loaders(:string, type), do: [&Types.String.load/1, type]
  def loaders(_primitive, type), do: [type]
  # def loaders(:binary_id, type), do: [Ecto.UUID, type]

  @impl Ecto.Adapter
  def ensure_all_started(_config, app_restart_type) do
    with {:ok, apps} <- Application.ensure_all_started(:vax, app_restart_type) do
      # Force restart.
      {:ok, (List.delete(apps, :vax) ++ [:vax])}
    end
  end

  @impl Ecto.Adapter
  @doc """
  Initializes the Antidote connection.

  XXX Do we need to put this connection somewhere?!
  """
  def init(config) do
    hostname = Keyword.get(config, :hostname, @default_hostname)
    port = Keyword.get(config, :port, @default_port)

    child_spec = %{
      id: :antidotec_pb_socket,
      start: {
        :antidotec_pb_socket,
        :start_link, [
          String.to_charlist(hostname),
          port
        ]
      }
    }

    {:ok, child_spec, %{}}
  end

  @doc """
  Implementation of Repo.get

  Returns `nil` if nothing is found. Returns the *value* if something was found.
  Raises an ArgumentError if using improperly.
  """
  def get(repo, meta, schema_module, id, opts) do
    IO.inspect {
      :get,
      repo,
      meta,
      schema_module,
      id,
      opts
    }

    throw :NotImplemented

    # source = schema_module.__schema__(:source)
    # riak_id = "#{id}"
    # result = Riak.find(meta.pid, repo.config[:database], source, riak_id)
    # case result do
    #   {:error, problem} -> raise ArgumentError, "Riak error: #{problem}"
    #   nil -> nil
    #   riak_map ->
    #     repo.load(schema_module, load_riak_map(riak_map))
    # end
  end

  @doc """
  Implementation of Repo.insert
  """
  def insert(repo, meta, struct_or_changeset, opts)
  def insert(repo, meta, changeset = %Ecto.Changeset{data: struct = %schema_module{}, changes: changes}, opts) do
    IO.inspect {
      :insert,
      :a,
      repo,
      meta,
      changeset,
      struct,
      schema_module,
      changes,
      opts
    }

    throw :NotImplemented

    # riak_map = build_riak_map(schema_module, changes)

    # source = schema_module.__schema__(:source)
    # [primary_key | _] = schema_module.__schema__(:primary_key)
    # riak_id = "#{Map.fetch!(struct, primary_key)}"

    # case do_insert(repo, meta, source, riak_map, riak_id, schema_module, opts) do
    #   :ok -> {:ok, repo.get(schema_module, riak_id)}
    #   :error -> {:error, changeset}
    # end
  end
  def insert(repo, meta, struct = %schema_module{}, opts) do
    IO.inspect {
      :insert,
      :b,
      repo,
      meta,
      struct,
      schema_module,
      opts
    }

    throw :NotImplemented

    # riak_map = dump(struct)

    # source = schema_module.__schema__(:source)
    # [primary_key | _] = schema_module.__schema__(:primary_key)
    # riak_id = "#{Map.fetch!(struct, primary_key)}"

    # case do_insert(repo, meta, source, riak_map, riak_id, schema_module, opts) do
    #   :ok -> {:ok, repo.get(schema_module, riak_id)}
    #   :error -> {:error, Ecto.Changeset.change(struct)}
    # end
  end

  # defp do_insert(repo, meta, source, riak_map, riak_id, schema_module, _opts) do
  #   case Riak.update(meta.pid, riak_map, repo.config[:database], source, riak_id) do
  #     {:ok, riak_map} ->
  #       res = repo.load(schema_module, load_riak_map(riak_map))
  #       {:ok, res}
  #     other ->
  #       other
  #   end
  # end

  # @doc """
  # Implementation of Repo.delete
  # """
  # def delete(repo, meta, struct_or_changeset, opts)
  # def delete(_repo, _meta, changeset = %Ecto.Changeset{valid?: false}, _opts) do
  #   {:error, changeset}
  # end
  # def delete(repo, meta, %Ecto.Changeset{data: struct = %_schema_module{}}, opts) do
  #   delete(repo, meta, struct, opts)
  # end

  # def delete(repo, meta, struct = %schema_module{}, _opts) do
  #   source = schema_module.__schema__(:source)
  #   [primary_key | _] = schema_module.__schema__(:primary_key)
  #   riak_id = "#{Map.fetch!(struct, primary_key)}"
  #   if riak_id == "" do
  #     raise Ecto.NoPrimaryKeyValueError
  #   end

  #   case Riak.delete(meta.pid, repo.config[:database], source, riak_id) do
  #     :ok -> {:ok, struct}
  #     :error -> raise Ecto.StaleEntryError
  #   end
  # end
end

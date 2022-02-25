defmodule VaxTest do
  use ExUnit.Case
  doctest Vax

  alias VaxTest.Ecto.Example

  test "greets the world" do
    assert Vax.hello() == :world
  end

  test "playing directly with the Antidote client" do
    IO.puts ""

    {:ok, pid} = :antidotec_pb_socket.start_link('localhost', 8087)
    {:ok, {:interactive, txid}} = :antidotec_pb.start_transaction(pid, :ignore, [])

    counter_field = {"key", :antidote_crdt_counter_pn, "bucket"}
    IO.inspect {:counter_field, counter_field}

    counter_obj = :antidotec_counter.increment(5, :antidotec_counter.new())
    counter_value = :antidotec_counter.value(counter_obj)
    dirty_value = :antidotec_counter.dirty_value(counter_obj)
    IO.inspect {:counter_obj, counter_obj}
    IO.inspect {:counter_value, counter_value}
    IO.inspect {:dirty_value, dirty_value}

    update_ops = :antidotec_counter.to_ops(counter_field, counter_obj)
    IO.inspect {:update_ops, update_ops}

    # write values to antidote
    :ok = :antidotec_pb.update_objects(pid, update_ops, {:interactive, txid})
    IO.inspect {:updated_objects}

    # read values
    {:ok, [counter_obj]} = :antidotec_pb.read_objects(pid, [counter_field], {:interactive, txid})
    IO.inspect {:counter_obj, counter_obj}

    # get the actual values out of the CRDTs
    counter_value = :antidotec_counter.value(counter_obj)
    dirty_value = :antidotec_counter.dirty_value(counter_obj)
    IO.inspect {:counter_value, counter_value}
    IO.inspect {:dirty_value, dirty_value}

    :ok = :antidotec_pb.abort_transaction(pid, {:interactive, txid})
    IO.inspect {:aborted}
  end

  # iex> alice = %User{name: "Alice", age: 10, id: "33"}
  # iex> Repo.get(User, "33") == nil
  # true
  # iex> {:ok, %User{name: "Alice", age: 10, id: "33"}} = Repo.insert(alice)
  # iex> %user{name: "Alice", age: 10, id: "33"} = Repo.get(User, "33")
  # iex> {:ok, %User{name: "Alice", age: 10, id: "33"}} = Repo.delete(alice)
  # iex> Repo.get(User, "33") == nil
  # true

  test "initialize an account" do
    %Ecto.Changeset{valid?: true} = Example.init_account() |> IO.inspect()
  end

  test "create an account" do
    %Example.Account{} = Example.create_account()
  end
end

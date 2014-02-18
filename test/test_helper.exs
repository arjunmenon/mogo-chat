ExUnit.start
Hound.start [driver: "selenium"]
MogoChat.Dynamo.run()
Repo.start_link

defmodule MogoChat.TestCase do
  use ExUnit.CaseTemplate

  # Enable code reloading on test cases
  setup do
    Dynamo.Loader.enable
    :ok
  end
end


defmodule TestUtils do
  def app_path(path \\ "") do
    "http://localhost:#{MogoChat.Dynamo.config[:server][:port]}/#{path}"
  end


  def truncate_db_after_test do
    table_names = ["users", "messages", "rooms", "room_user_states"]
    sql = "TRUNCATE TABLE #{Enum.join(table_names, ", ")} RESTART IDENTITY CASCADE;"
    Repo.adapter.query(Repo, sql)
  end


  defmacro wait_helpers do
    quote do
      def wait_until(element, func \\ nil) do
        if until_element(element) do
          if func do
            apply(func, [])
          else
            true
          end
        else
          IO.inspect "The following element wasn't found:"
          throw element
        end
      end


      defp until_element(element, wait_time \\ 10) do
        new_wait_time = wait_time - 1
        :timer.sleep(1000)
        {strategy, identifier} = element

        if new_wait_time > 0 do
          try do
            find_element(strategy, identifier)
          catch
            _ ->
              until_element(element, new_wait_time)
          else
            _ ->
              true
          end
        else
          find_element(strategy, identifier)
        end
      end
    end
  end


  def create_user(name, email, role) do
    User.new(name: name, email: email, password: "password", role: role)
    |> User.encrypt_password()
    |> Repo.create
  end


  def create_admin(name, email) do
    create_user(name, email, "admin")
  end


  def create_member(name, email) do
    create_user(name, email, "member")
  end


  defmacro test_dynamo(dynamo) do
    quote do
      setup_all do
        Dynamo.under_test(unquote(dynamo))
        :ok
      end

      teardown_all do
        Dynamo.under_test(nil)
        :ok
      end
    end
  end

end
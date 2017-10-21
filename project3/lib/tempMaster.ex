defmodule TempMaster do
    def init do
        Process.register(self(), :master)
        pid = spawn fn -> TempActor.listen() end
        id = pid |> inspect |> String.slice(7..-4)
        Process.register(pid, :"#{id}")
        send_message(id)
        loop(id)
    end
    def loop(id) do
        receive do
            {:pong, value} -> send_message(id)
            # code
        end
        loop(id)
    end
    defp send_message(id) do
        IO.puts "Received pong at :master"
        IO.puts "Sending ping to #{id}"
        send :"#{id}", {:ping, "ping"}
    end
end
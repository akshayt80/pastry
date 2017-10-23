defmodule PastryNode do
    require Logger
    # TODO:- check loops where in scala until 5 runs till 4 but in elixir it runs till 5
    def init(numNodes, numRequests, id, base, nodeIdSpace) do
        # try using set
        Logger.debug "Initializing node: Node_#{id}"
        larger_leafs = []#MapSet.new
        smaller_leafs = []#Mapset.new
        table = [] # %{}
        numOfBack = 0

        table = for i <- 0..base-1 do
            [-1, -1, -1, -1]
        end

        listen(id, base, larger_leafs, smaller_leafs, table, numRequests, numNodes, nodeIdSpace, numOfBack)
    end
    # can be removed if we are using hash
    defp toBase4String(raw, base) do
        str = Integer.to_string(raw, 4)
        diff = base - String.length(str)
        # add padding of 0 in front
        if diff > 0 do
            str = String.pad_leading(str, base, "0")
        end
        #Logger.debug "raw: #{raw} base4: #{str}"
        str
    end
    def different_bit(nodeId1, nodeId2, base, bit, curr_pos) when (curr_pos == base) do
        # when first bit also doesn't match
        if bit < 0 do
            bit = 0
        else
            bit = bit + 1
        end
        bit
    end
    def different_bit(nodeId1, nodeId2, base, bit \\ -1, curr_pos \\ 0) do
        char1 = String.at(nodeId1, curr_pos)
        char2 = String.at(nodeId2, curr_pos)
        if (char1 == char2) and (bit == curr_pos-1) do
            bit = curr_pos
        end
        curr_pos = curr_pos + 1
        different_bit(nodeId1, nodeId2, base, bit, curr_pos)
    end
    # add nodes to leaf sets
    # TODO:- return large_leaf set and small leaf set and table
    defp add_buffer(all, larger_leafs, smaller_leafs, table, id, base, current, size) when current >= size do
        {larger_leafs, smaller_leafs, table}
    end
    defp add_buffer(all, larger_leafs, smaller_leafs, table, id, base, current \\ -1, size \\ 0) do
        if size == 0 do
            #Logger.debug "Node_#{id} size: #{length(all)}"
            size = length(all)
        end
        if current == -1 do
            current = 0
        end
        i = Enum.at(all, current)
        current = current + 1

        {larger_leafs, smaller_leafs, table} = add_node(i, larger_leafs, smaller_leafs, table, id, base)

        add_buffer(all, larger_leafs, smaller_leafs, table, id, base, current, size)
    end
    # TODO:- return large_leaf set and small leaf set and table
    defp add_node(newNode, larger_leafs, smaller_leafs, table, id, base) do
        if newNode > id and not(Enum.member?(larger_leafs, newNode)) do
            if length(larger_leafs) < 4 do
                larger_leafs = larger_leafs ++ [newNode]
            else
                if newNode < Enum.max(larger_leafs) do
                    larger_leafs = larger_leafs -- [Enum.max(larger_leafs)]
                    larger_leafs = larger_leafs ++ [newNode]
                end
            end
        else
            if newNode < id and not(Enum.member?(smaller_leafs, newNode)) do
                if length(smaller_leafs) < 4 do
                    smaller_leafs = smaller_leafs ++ [newNode]
                else
                    if newNode > Enum.min(smaller_leafs) do
                        smaller_leafs = smaller_leafs -- [Enum.min(smaller_leafs)]
                        smaller_leafs = smaller_leafs ++ [newNode]
                    end
                end
            end
        end
        # TODO:- thorough testing rquired of below logic
        samePrefix = different_bit(toBase4String(id, base), toBase4String(newNode, base), base)
        table_row = Enum.at(table, samePrefix)
        index = toBase4String(newNode, base) |> String.at(samePrefix) |> Integer.parse |> elem(0)
        #element_at_index = elem(Integer.pasre(String.at(toBase4String(i, base), samePrefix)), 0)
        element_in_row = Enum.at(table_row, index)
        if element_in_row == -1 do
            updated_row = List.replace_at(table_row, index, newNode)
            table = List.replace_at(table, samePrefix, updated_row)
        end
        {larger_leafs, smaller_leafs, table}
    end
    defp display(larger_leafs, smaller_leafs, table) do
        Logger.info "smaller leafs: #{inspect(smaller_leafs)}"
        Logger.info "larger_leafs: #{inspect(larger_leafs)}"
        for {row, pos} <- Enum.with_index(table) do
            Logger.info "row: #{pos} -> #{inspect(row)}"
        end
    end
    defp listen(id, base, larger_leafs, smaller_leafs, table, numRequests, numNodes, nodeIdSpace, numOfBack) do
        receive do
            {:startRouting, value} ->
                Logger.debug "Node_#{id} starting routing"
                spawn fn -> start_async_requests(numRequests, nodeIdSpace, id) end
            {:initialJoin, {from, group}} -> groupOne = group -- [id]
                Logger.debug "Node_#{id} groupOne: #{inspect(groupOne)}"
                {larger_leafs, smaller_leafs, table} = add_buffer(groupOne, larger_leafs, smaller_leafs, table, id, base)
                table = for i <- 0..base-1 do
                    table_row = Enum.at(table, i)
                    index = toBase4String(id, base) |> String.at(i) |> Integer.parse |> elem(0)
                    List.replace_at(table_row, index, id)
                end
                Logger.debug "Node_#{id} larger_leafs: #{inspect(larger_leafs)} smaller_leafs: #{inspect(smaller_leafs)} table: #{inspect(table)}"
                # send message to master
                # TODO:- check if the message has to be sent to actor from whose this message was received
                #send :master, {:finishedJoining, "finished joining"}
                send from, {:finishedJoining, "finished joining"}
            {:route, {type, from, to, hops}} -> # TODO:- Finish the implementation
                Logger.debug "Node_#{id} type: #{type} from: #{from} to: #{to} hops: #{hops}"
                if type == :join do
                    samePrefix = different_bit(toBase4String(id, base), toBase4String(to, base), base)
                    table_row = Enum.at(table, samePrefix)
                    Logger.debug "Node_#{id} type: #{type} sameprefix: #{samePrefix} table row: #{inspect(table_row)}"
                    index = toBase4String(to, base) |> String.at(samePrefix) |> Integer.parse |> elem(0)
                    if hops == -1 and samePrefix > 0 do
                        for i <- 0..samePrefix-1 do
                            send :"Node_#{to}", {:addRow, {i, Enum.at(table, i)}}
                        end
                    end
                    Logger.debug "Node_#{id} send addrow to sameprefix: #{samePrefix}"
                    send :"Node_#{samePrefix}", {:addRow, {samePrefix, Enum.at(table, samePrefix)}}

                    cond do
                       (length(smaller_leafs) > 0 and to >= Enum.min(smaller_leafs) and to <= id) or (length(larger_leafs) > 0 and to <= Enum.max(larger_leafs) and to >= id) ->
                            diff = nodeIdSpace + 10
                            nearest = -1
                            # in smaller leafs
                            if to < id do
                                # for i <- smaller_leafs do
                                #     if abs(to - i) < diff do
                                #         nearest = i
                                #         diff = abs(to - i)
                                #     end
                                # end
                                {nearest, diff} = get_nearest(to, smaller_leafs, nearest, diff)
                            # in larger leafs
                            else
                                # for i <- larger_leafs do
                                #     if abs(to - i) < diff do
                                #         nearest = i
                                #         diff = abs(to - i)
                                #     end
                                # end
                                {nearest, diff} = get_nearest(to, larger_leafs, nearest, diff)
                            end

                            if abs(to - id) > diff do
                                send :"Node_#{nearest}", {:route, {type, from, to, hops + 1}}
                            else
                                # send leaf set info
                                allLeaf = [id] ++ smaller_leafs ++ larger_leafs
                                send :"Node_#{to}", {:addLeaf, allLeaf}
                            end
                        length(smaller_leafs) < 4 and length(smaller_leafs) > 0 and to < Enum.min(smaller_leafs) ->
                            send :"Node_#{Enum.min(smaller_leafs)}", {:route, {type, from, to, hops + 1}}
                        length(larger_leafs) < 4 and length(larger_leafs) > 0 and to > Enum.max(larger_leafs) ->
                            send :"Node_#{Enum.max(larger_leafs)}", {:route, {type, from, to, hops + 1}}
                        (length(smaller_leafs) == 0 and to < id) or (length(larger_leafs) == 0 and to > id) ->
                            allLeaf = [id] ++ smaller_leafs ++ larger_leafs
                            send :"Node_#{to}", {:addLeaf, allLeaf}
                        Enum.at(table_row, index) != -1 ->
                            send :"Node_#{Enum.at(table_row, index)}", {:route, {type, from, to, hops + 1}}
                        to > id ->
                            send :"Node_#{Enum.max(larger_leafs)}", {:route, {type, from, to, hops + 1}}
                            send :master, {:notInBoth, "not in both"}
                        to < id ->
                            send :"Node_#{Enum.min(smaller_leafs)}", {:route, {type, from, to, hops + 1}}
                            send :master, {:notInBoth, "not in both"}
                        true -> Logger.info "Node_#{id} Impossible!!! type: #{type} from: #{from} to: #{to}"
                    end
                else
                    if type == :route do
                        Logger.debug "Node_#{id} in :route to: #{to}"
                        if id == to do
                            send :master, {:routeFinish, {from, to, hops + 1}}
                        else
                            samePrefix = different_bit(toBase4String(id, base), toBase4String(to, base), base)
                            table_row = Enum.at(table, samePrefix)
                            Logger.debug "Node_#{id} type: #{type} sameprefix: #{samePrefix} table row: #{inspect(table_row)}"
                            index = toBase4String(to, base) |> String.at(samePrefix) |> Integer.parse |> elem(0)
                            cond do
                               (length(smaller_leafs) > 0 and to >= Enum.min(smaller_leafs) and to < id) or (length(larger_leafs) > 0 and to <= Enum.max(larger_leafs) and to > id) ->
                                    diff = nodeIdSpace + 10
                                    nearest = -1
                                    # in smaller leafs
                                    if to < id do
                                        # for i <- smaller_leafs do
                                        #     if abs(to - i) < diff do
                                        #         nearest = i
                                        #         diff = abs(to - i)
                                        #     end
                                        # end
                                        {nearest, diff} = get_nearest(to, smaller_leafs, nearest, diff)
                                    # in larger leafs
                                    else
                                        # for i <- larger_leafs do
                                        #     if abs(to - i) < diff do
                                        #         nearest = i
                                        #         diff = abs(to - i)
                                        #     end
                                        # end
                                        {nearest, diff} = get_nearest(to, larger_leafs, nearest, diff)
                                    end

                                    if abs(to - id) > diff do
                                        send :"Node_#{nearest}", {:route, {type, from, to, hops + 1}}
                                    else
                                        #allLeaf = [id] ++ smaller_leafs ++ larger_leafs
                                        #send :"Node_#{to}", {:addLeaf, allLeaf}
                                        Logger.debug "Node_#{id}, route finished"
                                        send :master, {:routeFinish, {from, to, hops + 1}}
                                    end
                            length(smaller_leafs) < 4 and length(smaller_leafs) > 0 and to < Enum.min(smaller_leafs) ->
                                send :"Node_#{Enum.min(smaller_leafs)}", {:route, {type, from, to, hops + 1}}
                            length(larger_leafs) < 4 and length(larger_leafs) > 0 and to > Enum.max(larger_leafs) ->
                                send :"Node_#{Enum.max(larger_leafs)}", {:route, {type, from, to, hops + 1}}
                            (length(smaller_leafs) == 0 and to < id) or (length(larger_leafs) == 0 and to > id) ->
                                # current node is closest
                                send :master, {:routeFinish, {from, to, hops + 1}}
                            # TODO:- add routing table condition
                            Enum.at(table_row, index) != -1 ->
                                send :"Node_#{Enum.at(table_row, index)}", {:route, {type, from, to, hops + 1}}
                            to > id ->
                                send :"Node_#{Enum.max(larger_leafs)}", {:route, {type, from, to, hops + 1}}
                                send :master, {:notInBoth, "not in both"}
                            to < id ->
                                send :"Node_#{Enum.min(smaller_leafs)}", {:route, {type, from, to, hops + 1}}
                                send :master, {:notInBoth, "not in both"}
                            true -> Logger.info "Node_#{id} Impossible!!! type: #{type} from: #{from} to: #{to}"
                            end
                        end
                    end
                end
            {:addRow, {rowNum, newRow}} -> 
                # for i <- 0..3 do
                #     table_row = Enum.at(table, rowNum)
                #     element_at_index = Enum.at(table_row, i)
                #     if element_at_index == -1 do
                #         new_element = Enum.at(newRow, i)
                #         updated_row = List.replace_at(table_row, i, new_element)
                #         table = List.replace_at(table, i, updated_row)
                #     end
                # end 
                table = List.replace_at(table, rowNum, newRow)
            {:addLeaf, allLeaf} -> {larger_leafs, smaller_leafs, table} = add_buffer(allLeaf, larger_leafs, smaller_leafs, table, id, base)
                update_sent = for i <- smaller_leafs do
                    send :"Node_#{i}", {:update, {self(), id}}
                    :ok
                end
                numOfBack = numOfBack + length(update_sent)
                update_sent = for i <- larger_leafs do
                    send :"Node_#{i}", {:update, {self(), id}}
                    :ok
                end
                numOfBack = numOfBack + length(update_sent)
                # for routing table
                update_sent = for i <- 0..base-1  do
                    table_row = table |> Enum.at(i)
                    for j <- 0..3 do
                        element = table_row |> Enum.at(j)
                        if element != -1 do
                            send :"Node_#{element}", {:update, {self(), id}}
                            :ok
                        end
                    end
                end
                update_count = update_sent |> List.flatten |> Enum.count(fn(x) -> x != nil end)
                numOfBack = numOfBack + update_count
                table = for i <- 0..base-1 do
                    table_row = Enum.at(table, i)
                    index = toBase4String(id, base) |> String.at(i) |> Integer.parse |> elem(0)
                    List.replace_at(table_row, index, id)
                    #table = List.replace_at(table, i, updated_row)
                end
            {:update, {from, newNodeId}} -> {larger_leafs, smaller_leafs, table} = add_node(newNodeId, larger_leafs, smaller_leafs, table, id, base)
                # TODO:- check if this has to be sent to master
                send from, {:acknowledgement, "acknowledgement"}
            {:acknowledgement, value} -> numOfBack = numOfBack - 1
                if numOfBack == 0 do
                    send :master, {:finishedJoining, "finished joining"}
                end
            {:displayLeafAndRouting, value} -> display(larger_leafs, smaller_leafs, table)
                Logger.debug "Killing process: #{id}"
                Process.exit(self(), :normal)
        end
        listen(id, base, larger_leafs, smaller_leafs, table, numRequests, numNodes, nodeIdSpace, numOfBack)
    end
    defp get_nearest(to, leafs, nearest, diff) when leafs == [] do
        {nearest, diff}
    end
    defp get_nearest(to, leafs, nearest, diff) do
        [current | remaining_leafs] = leafs
        if abs(to - current) < diff do
            nearest = current
            diff = abs(to - current)
        end
        get_nearest(to, remaining_leafs, nearest, diff)
    end
    defp start_async_requests(numRequests, nodeIdSpace, id) do
        for i <- 0..numRequests-1 do
            # sending request every second to self
            :timer.sleep 1000
            to = :rand.uniform(nodeIdSpace - 1 )
            Logger.debug "Node_#{id} sending request: from: #{id} to: #{to}"
            send :"Node_#{id}", {:route, {:route, id, to, -1}}
        end
    end
end
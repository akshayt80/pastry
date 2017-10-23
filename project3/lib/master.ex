defmodule Master do
    require Logger
    # This will be master node
    # TODO:- check loops where in scala until 5 runs till 4 but in elixir it runs till 5
    def init(numNodes, numRequests) do
        Process.register(self(), :master)
        # TODO:- see if we have to remove nodeIdspace and use normal hashing
        base = round(:math.ceil(:math.log(numNodes) / :math.log(4)))
        nodeIdSpace = round(:math.pow(4, base))
        randomList = []
        groupOne = []
        # default first group size
        groupOneSize = if numNodes < 1024, do: numNodes, else: 1024

        numHops = 0
        numJoined = 0
        numRouted = 0
        # not in leaf and routing table
        numNotInBoth = 0
        numRouteNotInBoth = 0

        i = -1

        Logger.debug "Number of Nodes: #{numNodes}"
        Logger.debug "Node ID Space: 0 ~ #{nodeIdSpace - 1}"
        Logger.debug "Number of requests per node: #{numRequests}"

        # TODO:- see if anything can be done in set instead of list
        # add node ids to randomList
        # for n <- 0..nodeIdSpace do
        #     randomList = randomList ++ [n]
        # end
        randomList = 0..nodeIdSpace-1 |> Enum.to_list

        # shuffle the random list
        randomList = Enum.shuffle randomList

        Logger.info "list of nodes: #{inspect(randomList)}"
        # TODO:- remove following line
        #randomList = [0,1,7,9,5,8,10,11,14,15]

        # adding nodes to group one
        groupOne = for n <- 0..groupOneSize-1 do
            Enum.at(randomList, n)
        end

        # create nodes
        registry = for n <- 0..numNodes-1 do
            # TODO:- pass appropruate arguements to node
            pid = spawn fn -> PastryNode.init(numNodes, numRequests, Enum.at(randomList, n), base, nodeIdSpace) end
            Logger.debug "Registering: Node_#{Enum.at(randomList, n)}"
            Process.register(pid, :"Node_#{Enum.at(randomList, n)}")
            :"Node_#{Enum.at(randomList, n)}"
        end

        for i <- 0..groupOneSize-1 do
            id = Enum.at(randomList, i)
            send :"Node_#{id}", {:initialJoin, {self(), groupOne}}
        end
        listen(randomList, numNodes, numRequests, numJoined, numNotInBoth, numRouted, numHops, numRouteNotInBoth, groupOne, groupOneSize, registry)

    end
    defp listen(randomList, numNodes, numRequests, numJoined, numNotInBoth, numRouted, numHops, numRouteNotInBoth, groupOne, groupOneSize, registry) do
        receive do
            {:start, value} ->  Logger.debug "Joining"
                for i <- 0..groupOneSize-1 do
                    id = Enum.at(randomList, i)
                    send :"Node_#{id}", {:initialJoin, {self(), groupOne}}
                end
            {:finishedJoining, value} -> numJoined = numJoined + 1
                # TODO:- check if the following should be > instead of >=
                if numJoined >= groupOneSize do
                    if numJoined >= numNodes do
                        # TODO:- see if we want to make send async
                        send self(), {:startRouting, "start routing"}
                    else
                        send self(), {:secondryJoin, "secondary Joining"}
                    end
                end
            {:secondryJoin, value} -> startId = Enum.at(randomList, :rand.uniform numJoined)
                # TODO:- make sure route message works as expected in worker node
                send :"Node_#{startId}", {:route, {:join, startId, Enum.at(randomList, numJoined), -1}}
            {:startRouting, value} -> Logger.info "Join is finished"
                Logger.info "Now starting with routing"
                # TODO:- see if we can use gossip protocol here
                #for i <- 0..numNodes-1 do
                for i <- registry do
                    # right now this is async sending
                    #spawn fn -> send :"#{i}", {:startRouting, "Start Routing"} end
                    Logger.debug "sending start route to : #{i}"
                    send :"#{i}", {:startRouting, "Start Routing"}
                end
            {:notInBoth, value} -> numNotInBoth = numNotInBoth + 1
            {:routeFinish, {from, to, hops}} -> numRouted = numRouted + 1
                numHops = numHops + hops
                # for i <- 1..10 do
                #     if numRouted == ((numNodes * numRequests * i)/100) do
                #         Logger.info "#{i}0% routing finished"
                #     end
                # end
                if numRouted >= (numNodes * numRequests) do
                   Logger.info "Total routes: #{numRouted} Total hops: #{numHops}"
                   avg = numHops / numRouted
                   Logger.info "Average hops per route: #{avg}"
                   Logger.info "Closing simulation"
                   Process.exit(self(), :normal)
                end
            {:routeNotInBoth, value} -> numRouteNotInBoth = numRouteNotInBoth + 1
        end
        listen(randomList, numNodes, numRequests, numJoined, numNotInBoth, numRouted, numHops, numRouteNotInBoth, groupOne, groupOneSize, registry)
    end
end
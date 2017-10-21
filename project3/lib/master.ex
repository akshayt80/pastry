defmodule Master do
    # This will be master node
    def init(numNodes, numRequests) do
        Process.registry(self(), :master)
        # TODO:- see if we have to remove nodeIdspace and use normal hashing
        base = round(:math.ceil(:math.log(numNodes) / :math.log(4)))
        nodeIdSpace = round(:math.pow(4, base))
        randomList = []
        groupOne = []
        # default first group size
        groupOneSize = if numNodes < 1024, do: numNodes, else: 1024
        numHops = 0
        numJoined = 0
        numNotInBoth = 0
        numRouteNotInBoth = 0
        numRouted = 0

        i = -1

        Logger.debug "Number of Nodes: #{numNodes}"
        Logger.debug "Node ID Space: 0 ~ #{nodeIdSpace - 1}"
        Logger.debug "Number of requests per node: #{numRequests}"

        # TODO:- see if anything can be done in set instead of list
        # add node ids to randomList
        for n <- 0..nodeIdSpace do
            randomList = randomList ++ [n]
        end

        # shuffle the random list
        randomList = Enum.shuffle randomList

        # adding nodes to group one
        for n <- 0..groupOneSize do
            groupOne = groupOne ++ [Enum.at(randomList, n)]
        end

        # create nodes
        for n <- 0..numNodes do
            # TODO:- pass appropruate arguements to node
            pid = spawn fn -> Node.init(numNodes, numRequests, n, base, nodeIdSpace) end
            Process.register(pid, :"Node_#{n}")
        end

        listen()

    end
    defp listen(randomList, numNodes, numJoined, numNotInBoth, numRouted, numHops, numRouteNotInBoth, groupOne, groupOneSize) do
        receive do
            {:start, value} ->  Logger.debug "Joining"
                for i <- 0..groupOneSize do
                    id = Enum.at(randomList, i)
                    send :"Node_#{id}", {:initialJoin, groupOne}
                end
            {:finishedJoining, value} -> numJoined = numJoined + 1
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
            {:startRouting, value} -> Logger.debug "Join is finished"
                Logger.debug "Now starting with routing"
                # TODO:- see if we can use gossip protocol here
                for i <- 0..numNodes do
                    # right now this is async sending
                    spawn fn -> send :"Node_#{i}", {:startRouting, "Start Routing"} end
                end
            {:notInBoth, value} -> numNotInBoth = numNotInBoth + 1
            {:routeFinish, {from, to, hops}} -> numRouted = numRouted + 1
                numHops = numHops + 1
                if numRouted >= (numNodes * numRequests) do
                   Logger.info "Total routes: #{numRouted} Total hops: #{numHops}"
                   avg = numHops / numRouted
                   Logger.info "Average hops per route: #{avg}"
                   Logger.info "Closing simulation"
                   Process.exit(self(), :normal)
                end
            {:routeNotInBoth, value} -> numRouteNotInBoth = numRouteNotInBoth + 1
        end
        listen(randomList, numNodes, numJoined, numNotInBoth, numRouted, numHops, numRouteNotInBoth, groupOne, groupOneSize)
    end
end
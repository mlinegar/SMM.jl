
# the goal here is to have a convenient way of 
# storing the different evaluations.
# That includes the realizations of the objective
# function, the moments, and the value of the parameters
# that went in the evaluation.
# It might also include additional information
#
# so usually we'll have to refer to a chain number, an iteration, and an object
# which might be either a moment, a parameter, or an output.
#
# Because the chains might grow over time and because storing a in a DataFrame 
# is not always easy, we are going to use vectors for each.


# defining an abstract chain type in case 
# some algorithm need additional information
# on top of (eval, moment, parameter)
abstract AbstractChain


# the default chain type
# we create a dictionary with arrays
# for each parameters
type Chain
  i::Int             # current index
  evals     ::DataArray   # DataArray of evaluations (can hold NA)
  accept    ::DataArray   # DataArray of accept/reject(can hold NA)
  parameters::Dict   # dictionary of arrays(L,1), 1 for each parameter
  moments   ::Dict      # dictionary of DataArrays(L,1), 1 for each moment

  function Chain(MProb,L)
    evals      = @data([0.0 for i = 1:L])
    accept     = @data([false for i = 1:L])
    parameters = { x => zeros(L) for x in ps_names(MProb) }
    moments    = { x => @data([0.0 for i = 1:L]) for x in ms_names(MProb) }
    return new(0,evals,accept,parameters,moments)
  end
end


# TODO
#setindex!(Chain,idx,val)
# see appendEval! below

#getindex(Chain,idx) => returns a "ChainRow"
# a bit tricky because we don't know for how many cols there are params, moments etc

# i decided to return a 1-row dataframe.
function getindex(c::Chain, i::Int)
    r = DataFrame(i = i, value = c.evals[i], accept = c.accept[i])
    r = cbind(r,getParamDF(c,i),getMomentsDF(c,i))
    return r
end

# can also return a range of the dataframe
function getindex(c::Chain, i::UnitRange{Int})
    r = DataFrame(i = i, value = c.evals[i], accept = c.accept[i])
    r = cbind(r,getParamDF(c,i),getMomentsDF(c,i))
    return r
end

# return parameter dict as a DataFrame
function getParamDF(c::Chain)
    cols = [c.parameters[k] for k in keys(c.parameters)]
    cnames = Array(Symbol,length(c.parameters))
    pkeys = collect(keys(c.parameters))
    for i in 1:length(pkeys)
        cnames[i] = symbol(pkeys[i])
    end
    return DataFrame(cols, cnames)
end

# return paramDF at row i
function getParamDF(c::Chain,i)
    r = getParamDF(c)
    return r[i,:]
end

# return moments dict as a DataFrame
function getMomentsDF(c::Chain)
    cols = [c.moments[k] for k in keys(c.moments)]
    cnames = Array(Symbol,length(c.moments))
    pkeys = collect(keys(c.moments))
    for i in 1:length(pkeys)
        cnames[i] = symbol(pkeys[i])
    end
    return DataFrame(cols, cnames)
end

function getMomentsDF(c::Chain,i)
    r = getMomentsDF(c)
    return r[i,:]
end


# appends values from objective function
# at CURRENT iteration
function appendEval!(chain::Chain, vals::Dict, ACC::Bool)
  chain.evals[chain.i] = vals["value"]
  chain.accept[chain.i] = ACC
  for (k,v) in vals["moments"]
    chain.moments[k][chain.i] = v
  end
  for (k,v) in vals["params"]
    chain.parameters[k][chain.i] = v
  end
  return nothing
end


function getEvals(ch::Chain)
    return ch.evals
end

function getMoments(ch::Chain)
    return ch.moments
end




## MULTIPLE CHAINS
## ===============

# Stores multilpe chains
type MChain
  n :: Int # number of chains
  chains :: Array

  function MChain(n,MProb,L)
    chains = [ Chain(MProb,L) for i in 1:n ]
    return new(n,chains)
  end
end



# methods for MChain
function appendEval!(MC::MChain, which::Int, vals::Dict, acc::Bool)
    appendEval!(MC.chains[which],vals,acc)
end

# update the iteration count on each chain
function updateIter!(MC::MChain)
    for ix in 1:MC.n
        MC.chains[ix].i += 1
    end 
end

# gets evals array from chain number "which"
# in multiple chain object ch
function getEvals(ch::MChain,which::Int)
    return ch.chains[which].evals
end

function getMoments(ch::MChain,which::Int)
    return ch.chains[which].moments
end





module TestAlgo

using FactCheck, DataFrames

include("../src/mopt.jl")


p    = ["a" => 3.1 , "b" => 4.9]
pb   = [ "a" => [0,1] , "b" => [0,1] ]
moms = [
	"alpha" => [ 0.8 , 0.02 ],
	"beta"  => [ 0.8 , 0.02 ],
	"gamma" => [ 0.8 , 0.02 ]
]

mprob = Mopt.MProb(p,pb,Mopt.Testobj,moms)

facts("testing MAlgoRandom Constructor") do

	context("checking members") do

		opts =["N"=>3,"shock_var"=>1.0,"mode"=>"serial","maxiter"=>100,"path"=>"."] 

		MA = Mopt.MAlgoRandom(mprob,opts)

		@fact isa(MA,Mopt.MAlgo) => true
		@fact isa(MA,Mopt.MAlgoRandom) => true
		@fact isa(MA.m,Mopt.MProb) => true

		@fact MA.i => 0
		@fact MA.MChains.n => opts["N"]

		for ix = 1:opts["N"]
			@fact MA.current_param[ix] => p 
		end

	end

	context("checking getters/setters on MAlgo") do

		opts =["N"=>3,"shock_var"=>1.0,"mode"=>"serial","maxiter"=>100,"path"=>"."] 
		MA = Mopt.MAlgoRandom(mprob,opts)

		# getters
		@fact MA["N"] => opts["N"]
		@fact MA["mode"] => opts["mode"]

		# setter
		MA["newOption"] = "hi"
		@fact MA["newOption"] => "hi"

	end

end



facts("testing MAlgo methods") do
	
	context("testing evaluateObjective(algo)") do

		opts =["N"=>3,"shock_var"=>1.0,"mode"=>"serial","maxiter"=>100,"path"=>"."] 
		MA = Mopt.MAlgoRandom(mprob,opts)

		which_chain = 1
		x = Mopt.evaluateObjective(MA,which_chain)

		@fact haskey(x,"value") => true
		@fact x["params"] => p
		@fact haskey(x,"moments") => true

		# change p on MA:
		newp = ["a" => 103.1 , "b" => -2.2]
		MA.candidate_param[which_chain] = newp
		x = Mopt.evaluateObjective(MA,1)
		@fact x["params"] => newp
	end


	context("updateChains!(algo)") do

		opts =["N"=>3,"shock_var"=>1.0,"mode"=>"serial","maxiter"=>100,"path"=>"."] 
		MA = Mopt.MAlgoRandom(mprob,opts)

		@fact MA.MChains.chains[1].i => 0
		@fact MA.i => 0

		Mopt.updateChains!(MA)

		# compute objective function once
		v = Mopt.Testobj(p,moms,["alpha", "beta","gamma"])

		# each chain must have those values
		for ix in 1:opts["N"]
			ch = Mopt.getChain(MA,ix)	# get each chain
			@fact ch.i => 1
			@fact ch.evals[1] => v["value"]
			@fact ch.accept[1] => true # all true in first eval
			for k in keys(ch.parameters)
				@fact ch.parameters[k][1] => v["params"][k]
			end
			for k in keys(ch.moments)
				@fact ch.moments[k][1] => v["moments"][k]
			end
		end # all chains
	end
end




end # module


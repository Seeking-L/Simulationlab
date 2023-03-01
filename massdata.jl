struct Mass
	name::String
	# name1::String
	hname::String
	temperature_limit::Vector{Float64}
	pressure_limit::Vector{Float64}
	number::Int
end

water=Mass("水","water",[273.06, 647.09],[1, 2200],1)

Ammonia=Mass("氨气","Ammonia",[196.15, 405.15],[1, 1100],2)

mass_list = [water, Ammonia]

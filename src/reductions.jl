## ----------  Reductions

"""
	$(SIGNATURES)

Apply `reduceFct` to each variable in each `GroupStats` object for which this is defined.
"""
function reduce_stats(
        scV :: Vector{StatsCollection{T}},
        reduceFct
        ) where T
    
    nSim = length(scV);
	meanStats = deepcopy(scV[1]); 

	grps = get_groups(scV[1]);
	for grp in grps
		# Make vector of this field across all simulations
		# E.g., gpaYpS
        mStatsV = [get_mstats(scV[j], grp)  for j = 1 : nSim];
        newField = reduce_stats(mStatsV, reduceFct);
        replace_mstats!(meanStats, newField);
    end
    return meanStats
end


"""
	$(SIGNATURES)

Apply a scalar reduction function to all numeric fields in a `Vector` of `ModelStats`.

# Example
```
reduce
```
"""
function reduce_stats(
        statV :: AbstractVector{ModelStats{T}}, 
        reduceFct
        ) where T

    statsOut = deepcopy(statV[1]);
    varNameV = var_names(statV[1]);
    for varName in varNameV
        # Value from each `ModelStats` object.
        varMean = reduce_one_field(statV, varName, reduceFct);
        # Cannot reduce all types of fields.
        if !isnothing(varMean)
            set_values!(statsOut, varName, varMean);
        end
    end
    return statsOut
end


"""
    $(SIGNATURES)

Apply `reduceFct` to one field in a vector of objects.
Returns `nothing` if reduction not possible. E.g., because `reduceFct` is not defined for a given field or it returns the wrong type.
"""
function reduce_one_field(
        oVecV :: AbstractVector{ModelStats{T1}},  
        pn,  
        reduceFct :: Function
        ) where T1

    n = length(oVecV);
    fieldV = [get_values(oVecV[iObj], pn)  for iObj = 1 : n];
    if isa(fieldV[1], AbstractArray)
        xM = reduce_array_vector(fieldV, reduceFct);
    else
        xM = reduce_scalar_vector(fieldV, reduceFct);
    end
    return xM
end




# ------------
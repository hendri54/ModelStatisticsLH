module ModelStatisticsLH

using DocStringExtensions

export GroupStats, VarInfo
export n_groups, get_meta, validate_stats, data_table
export has_variable, add_variable!, delete_variable!, get_values, set_values!


## ---------------  VarInfo


"""
	$(SIGNATURES)

Information about a variable of type `T` with bounds. The variable is expected to be numeric, but it could be anything. The bounds may not make sense in all cases.

An optional description can be stored for nicer display.
"""
struct VarInfo{T} 
    varName :: Symbol
    lb :: T
    ub :: T
    description :: String
end

Base.eltype(v :: VarInfo{T}) where T = T;
description(v :: VarInfo{T}) where T = v.description;

VarInfo(vName, lb, ub) = VarInfo(vName, lb, ub, string(vName));

Base.show(io :: IO, vi :: VarInfo{T}) where T = 
    print(io, "VarInfo for $(vi.varName)");


## ---------------  GroupStats


"""
	$(SIGNATURES)

Holds statistics arranged by a single group. For each variable, a `VarInfo` object holds info needed to display and check the data.
"""
mutable struct GroupStats
    groupNames :: Vector{Symbol}
    varMeta :: Vector{VarInfo}
    values :: Dict{Symbol, Any}
end


"""
    $(SIGNATURES)

Constructor, using a `Vector{VarInfo}` as input. 
"""
function GroupStats(grNames :: AbstractVector{Symbol},
    varMeta :: Vector{VarInfo})

    ng = length(grNames);
    values = Dict{Symbol, Any}();
    for v in varMeta
        values[v.varName] = Vector{eltype(v)}(undef, ng);
    end

    return GroupStats(grNames, varMeta, values)
end

GroupStats(grNames :: AbstractVector{Symbol}) = 
    GroupStats(grNames, Vector{VarInfo}(), Dict{Symbol, Any}());


Base.show(io :: IO, g :: GroupStats) = 
    print(io, "GroupStats with $(n_groups(g)) groups and $(n_vars(g)) variables.");


"""
	$(SIGNATURES)

Check that 
- all data are inside bounds
"""
function validate_stats(g :: GroupStats)
    isValid = true;

    if n_vars(g) > 0
        for vMeta in g.varMeta
            varValid, failStr = validate_variable(g, vMeta);
            if !varValid
                @warn "$(vMeta.varName) not valid:  " * failStr;
                isValid = false;
            end
        end
    end

    return isValid
end


"""
	$(SIGNATURES)

Validate one variable.
"""
function validate_variable(g :: GroupStats, vMeta :: VarInfo{T}) where T
    vName = vMeta.varName;
    @assert haskey(g.values, vName)  "$vMeta not found"
    valueV = get_values(g, vName);

    failStr = "";
    isValid = true;

    if eltype(valueV) != T
        isValid = false;
        failStr = failStr * "Wrong eltype /";
    end
    if any(valueV .< vMeta.lb)
        isValid = false;
        failStr = failStr * "Values below lower bound /";
    end
    if any(valueV .> vMeta.ub)
        isValid = false;
        failStr = failStr * "Values above upper bound /";
    end
    return isValid, failStr
end


## ----------  Properties

"""
    $(SIGNATURES)

Number of groups in `GroupStats`.
"""
n_groups(g :: GroupStats) = length(g.groupNames);

n_vars(g :: GroupStats) = length(g.varMeta);

Base.eltype(g :: GroupStats, vName :: Symbol) =
    eltype(get_meta(g, vName));


## ----------  Retrieve

"""
	$(SIGNATURES)

Return all variable names.
"""
function var_names(g :: GroupStats)
    return [vm.varName  for vm in g.varMeta];
end


"""
    $(SIGNATURES)

Return meta info for a variable. Errors if not found.
"""
function get_meta(g :: GroupStats, vName :: Symbol)
    vMeta = _get_meta(g, vName);
    @assert !isnothing(vMeta)  "$vName not found"
    return vMeta
end

# Returns nothing if not found.
function _get_meta(g :: GroupStats, vName :: Symbol)
    found = false;
    vmOut = nothing;
    for vm in g.varMeta
        if vm.varName == vName
            found = true;
            vmOut = vm;
            break;
        end
    end
    return vmOut
end

function meta_index(g :: GroupStats, vName :: Symbol)
    found = false;
    idx = nothing;
    for (j, vm) in enumerate(g.varMeta)
        if vm.varName == vName
            found = true;
            idx = j;
            break;
        end
    end
    return idx
end


"""
	$(SIGNATURES)

Do `GroupStats` contain variable `vName`?
"""
has_variable(g :: GroupStats, vName :: Symbol) = 
    !isnothing(_get_meta(g, vName));


"""
    $(SIGNATURES)

Return values for a variable. Errors if not found.
"""
get_values(g :: GroupStats, vName :: Symbol) =
    g.values[vName];


"""
	$(SIGNATURES)

Set values for a variable. Errors if variable does not exist.

# Example
```julia
set_values!(g, :x, [1,2,3]);
```
"""
function set_values!(g :: GroupStats, vName :: Symbol, newValues) 
    @assert size(newValues) == (n_groups(g),)  "Invalid size: $(size(newValues))";
    vMeta = get_meta(g, vName);
    g.values[vName] = convert.(eltype(g, vName), newValues);
end


"""
	$(SIGNATURES)

Add a variable.

# Arguments
- `vInfo`: Can be a `VarInfo` or a `Tuple` of values that can be fed into the `VarInfo` constructor.

# Example
```julia
add_variable!(g, (:vName, 0.0, 1.0), [1,2,3]);
```
"""
add_variable!(g :: GroupStats, vInfo, newValues) = 
    add_variable!(g, VarInfo(vInfo...), newValues);

function add_variable!(g :: GroupStats, vInfo :: VarInfo, newValues)
    @assert size(newValues) == (n_groups(g),)  "Invalid size: $(size(newValues))";
    vName = vInfo.varName;
    @assert !has_variable(g, vName)  "$vName not found"
    push!(g.varMeta, vInfo);
    g.values[vName] = convert.(eltype(vInfo), newValues);
end


"""
	$(SIGNATURES)

Delete a variable. Errors if it does not exist.
"""
function delete_variable!(g :: GroupStats, vName :: Symbol)
    idx = meta_index(g, vName)    
    @assert idx > 0  "$vName not found"
    deleteat!(g.varMeta, idx);
    delete!(g.values, vName);
end


"""
	$(SIGNATURES)

Show a summary table for selected variables and groups. Because each variable can be of a different type, there is no good way of returning a single table as values (without introducing more dependencies that seems optimal).
"""
function data_table(g :: GroupStats; vars = var_names(g))
    tbM = fill("", n_groups(g), length(vars) + 1);
    
    for ig = 1 : n_groups(g)
        tbM[ig,1] = string(g.groupNames[ig]);
    end

    for (j, varName) in enumerate(vars)
        tbM[:, j+1] = format_values(get_values(g, varName));
    end
    return tbM
end

format_values(v :: Vector{I}) where I <: Integer = 
    string.(v);

format_values(v :: Vector{R}) where R <: Real = 
    string.(round.(v; digits = 2));

format_values(v) = string.(v);


end #module
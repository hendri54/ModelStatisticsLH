"""
	$(SIGNATURES)

Container for a collection of `ModelStats`. May also contain nested `StatsCollection`s.
"""
struct StatsCollection{T}
    d :: Dict{Any, Union{StatsCollection, ModelStats}}
end


## -----------  Constructor

StatsCollection{T}() where T = StatsCollection{T}(
    Dict{Any, Union{StatsCollection, ModelStats}}()
);


## -----------  Adding stats

"""
	$(SIGNATURES)

Add `ModelStats` or a nested `StatsCollection`.

# make recursive +++++
"""
function add_mstats!(m :: StatsCollection{T}, s :: ModelStats{T2}) where {T, T2}
    @assert !has_mstats(m, T2) "$s already exists in $m";
    m.d[T2] = s;
    return nothing;
end

"""
	$(SIGNATURES)

Delete `ModelStats`.

# make recursive +++++
"""
function delete_mstats!(m :: StatsCollection{T}, msName) where {T}
    @assert has_mstats(m, msName) "$msName not found in $m";
    delete!(m.d, msName);
    return nothing;
end

"""
	$(SIGNATURES)

Replace `ModelStats`. Add it if it does not exist.

# make recursive +++++
"""
function replace_mstats!(m :: StatsCollection{T}, s :: ModelStats{T2}) where {T, T2}
    m.d[T2] = s;
    return nothing;
end


## -----------  Retrieve

"""
	$(SIGNATURES)

List of all the `groups`.

# make recursive +++++
"""
get_groups(m :: StatsCollection{T}) where T = keys(m.d);


"""
	$(SIGNATURES)

Does the `ModelStats{groups}` object exist?

make recursive +++++
"""
function has_mstats(m :: StatsCollection{T}, groups) where T
    return haskey(m.d, groups);
end

"""
	$(SIGNATURES)

Retrieve the `ModelStats{groups}` object. Errors if `groups` not found.

make recursive +++++
"""
function get_mstats(m :: StatsCollection{T}, groups) where T
    @assert has_mstats(m, groups)  "$groups not found in $m"
    ms = m.d[groups];
    return ms
end

"""
	$(SIGNATURES)

Retrieve a statistic. Groups are specified.
"""
get_stats(m :: StatsCollection{T}, groups, statName :: Symbol) where T =
	getproperty(get_mstats(m, groups), statName);
    

"""
	$(SIGNATURES)

Retrieve a statistic without providing groups.

# Example
```julia
get_stats(m, :workTime_gp) == get_stats(m, (:gpa, :parental), :workTime)
# Equivalently
m.workTime_gp == get_stats(m, :workTime_gp)
m.workTime_gp[2,3] == get_stats(m, :workTime_gp)[2,3]
```
"""
get_stats(m :: StatsCollection{T}, sg :: Symbol) where T = 
    get_stats(m, groups_from_name(m, sg), statname_from_name(m, sg));

function Base.getproperty(m :: StatsCollection{T}, sg :: Symbol) where T 
    if sg == :d
        return getfield(m, :d)
    else
        return get_stats(m, sg);
    end
end

Base.getindex(m :: StatsCollection{T}, sg :: Symbol, idx...) where T = 
    get_stats(m, sg)[idx...];


"""
	$(SIGNATURES)

Set values for a statistic.

# Example
```julia
set_stats!(m, (:gpa, :parental), [1,2,3])
set_stats!(m, :workTime_gp, [1,2,3])
# Also with indices
m.workTime_gp[2,3] = x
```
"""
function set_stats!(m :: StatsCollection{T}, groups, statName :: Symbol, x) where T
	setproperty!(get_mstats(m, groups), statName, x);
end

Base.setindex!(m :: StatsCollection{T}, sg :: Symbol, x, idx...) where T = 
    set_stats!(m, sg)[idx...] .= x;

    
"""
	$(SIGNATURES)

Mapping of name of a statistic into groups. User defines this for each parametric `StatsCollection{T}`.

# Example:
```julia
groups_from_name(m, :workTime_gp) == (:gpa, :parental)
```
"""
groups_from_name(m :: StatsCollection, statName :: Symbol) = 
    error("User defines this for each parametric StatsCollection");

"""
	$(SIGNATURES)

Mapping of name of a statistic into its name without the group info. User defines this for each parametric `StatsCollection{T}`.

# Example:
```julia
groups_from_name(m, :workTime_gp) == :workTime
```
"""
statname_from_name(m :: StatsCollection, statName :: Symbol) = 
    error("User defines this for each parametric StatsCollection");


## -------  Testing

function make_test_scollection(T, rng)
    sc = StatsCollection{T}();
    tmsV = (:TMS, :TMS2, :TMS3);
    nVarV = (3, 4, 5);
    for j = 1 : length(tmsV)
        add_mstats!(sc, make_test_model_stats(tmsV[j], nVarV[j], rng));
    end
    return sc
end


# ------------
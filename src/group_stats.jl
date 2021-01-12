## ---------------  GroupStats


"""
	$(SIGNATURES)

Container that holds model statistics (arrays or scalars) and meta information. 
For each variable, a `VarInfo` object holds info needed to display and check the data.

The `T` parameter is not used anywhere, but it enables the user to construct different parametric `ModelStats{T}` and dispatch on those. 
"""
struct ModelStats{T}
    meta :: Dict{Symbol, Any}
    varMeta :: Dict{Symbol, VarInfo}
    values :: Dict{Symbol, Any}
end

# Blank
ModelStats{T}() where T = ModelStats{T}(Dict{Symbol, Any}(), 
    Dict{Symbol, VarInfo}(), Dict{Symbol, Any}());

# Meta only
ModelStats{T}(meta :: Dict{Symbol, Any}) where T = ModelStats{T}(meta, 
    Dict{Symbol, VarInfo}(), Dict{Symbol, Any}());

# Meta and Vector{VarInfo}. Easier to provide than `Dict`
ModelStats{T}(meta :: Dict{Symbol, Any}, 
    viV :: AbstractVector{VT}) where {T, VT <: VarInfo} =
    ModelStats{T}(meta, dict_from_vector(viV));

function dict_from_vector(viV :: AbstractVector{VT}) where VT <: VarInfo
    d = Dict{Symbol, VarInfo}();
    for vi in viV
        d[var_name(vi)] = vi;
    end
    return d
end


"""
    $(SIGNATURES)

Constructor. Values are not provided. They are initialized with default values (usually zeros).

# Examples
```
meta = Dict{Symbol,Any}([:group => :test]);
T = (:x, :y);
s = ModelStats{T}(meta);
s = ModelStats{T}(meta, [VarInfo(:test, "Test", Float64)]);
s = ModelStats{T}(meta, Dict{Symbol, VarInfo}([:test => VarInfo(:test, "Test", Float64)]));
```
"""
function ModelStats{T}(meta :: Dict{Symbol, Any},
    varMeta :: Dict{Symbol, VarInfo}) where T

    values = init_values(varMeta);
    return ModelStats{T}(meta, varMeta, values)
end


"""
	$(SIGNATURES)

Initialize all arrays for which size info is known.
"""
function init_values(varMeta :: Dict{Symbol, VarInfo})
    values = Dict{Symbol, Any}();
    for (varName, vInfo) in varMeta
        values[varName] = init_values(vInfo);
    end
    return values
end

Base.show(io :: IO, g :: ModelStats{T}) where T = 
    print(io, "ModelStats{$T} with $(n_vars(g)) variables.");


## -----------  Access

"""
	$(SIGNATURES)

This allows the user to access values using dot notation:
`g.x == get_values(g, :x)`    
"""
function Base.getproperty(g :: ModelStats{T}, v :: Symbol) where T
    # Spelling out the fields gives type stability.
    if v === :meta
        return getfield(g, :meta);
    elseif v === :varMeta
        return getfield(g, :varMeta);
    elseif v === :values
        return getfield(g, :values);
    else
        return get_values(g, v);
    end
end

# This allows functions that operate on properties to work.
Base.propertynames(g :: ModelStats{T}) where T = 
    var_names(g);

Base.hasproperty(g :: ModelStats{T}, v :: Symbol) where T =
    has_variable(g, v);

"""
	$(SIGNATURES)

Retrieve selected elements of a variable.

# Example
```
z = g.x[1:2, 3, 4]
```
"""
Base.getindex(g :: ModelStats{T}, v :: Symbol, idx...) where T = 
    get_values(g, v)[idx...];


"""
	$(SIGNATURES)

Set values of a variable.

# Example
```
g.x = [1,2,3];
```
"""
function Base.setproperty!(g :: ModelStats{T}, v :: Symbol, values) where T
    set_values!(g, v, values)
end

"""
	$(SIGNATURES)

# Example
```
g.x[1:2, 3:5] = rand(2,3);
g.x[1:2, 3:5] .= 0.5;
```
"""
Base.setindex!(g :: ModelStats{T}, v :: Symbol, 
    newValue :: Number, idx :: Integer) where T = 
    get_values(g, v)[idx] = newValue;

Base.setindex!(g :: ModelStats{T}, v :: Symbol, newValueV, idx...) where T = 
    get_values(g, v)[idx...] .= newValueV;

# """
#     $(SIGNATURES)

# Number of groups in `ModelStats`.
# """
# n_groups(g :: ModelStats) = length(group_names(g));

# """
# 	$(SIGNATURES)

# Group names as Symbols.
# """
# group_names(g :: ModelStats) = g.groupNames;

"""
	$(SIGNATURES)

Number of variables.
"""
n_vars(g :: ModelStats{T}) where T = length(g.varMeta);

"""
	$(SIGNATURES)

Return all variable names.
"""
var_names(g :: ModelStats{T}) where T = keys(g.varMeta);

Base.eltype(g :: ModelStats{T}, vName :: Symbol) where T =
    eltype(var_meta(g, vName));


## ----------  Validation

"""
	$(SIGNATURES)

Check that 
- all data are inside bounds
"""
function validate_stats(g :: ModelStats{T}; silent :: Bool = true) where T
    isValid = true;
    if n_vars(g) > 0
        for vName in var_names(g)
            isValid = isValid  &&  validate_variable(g, vName; silent = silent);
        end
    end
    return isValid
end


"""
	$(SIGNATURES)

Validate one variable.
"""
function validate_variable(g :: ModelStats{T}, vName :: Symbol;
    silent :: Bool = true) where T

    @assert haskey(g.values, vName)  "$vName not found"
    valueV = get_values(g, vName);
    isValid = check_var(var_meta(g, vName), valueV; silent = false);
    return isValid
end


## ----------  Retrieve

"""
	$(SIGNATURES)

Retrieve meta info (not for a variable).
"""
get_meta(g :: ModelStats{T}, mName :: Symbol) where T = 
    g.meta[mName];

"""
    $(SIGNATURES)

Return meta info for a variable. Errors if not found.
"""
function var_meta(g :: ModelStats, vName :: Symbol)
    vMeta = _var_meta(g, vName);
    @assert !isnothing(vMeta)  "$vName not found"
    return vMeta
end

# Returns nothing if not found.
function _var_meta(g :: ModelStats{T}, vName :: Symbol) where T
    if haskey(g.varMeta, vName)
        return g.varMeta[vName];
    else
        return nothing
    end
end

"""
	$(SIGNATURES)

Do `GroupStats` contain variable `vName`?
"""
has_variable(g :: ModelStats{T}, vName :: Symbol) where T = 
    haskey(g.varMeta, vName);


"""
    $(SIGNATURES)

Return values for a variable. Errors if not found, unless `defaultValue` is provided.
"""
function get_values(g :: ModelStats{T}, vName :: Symbol;
    defaultValue = :error) where T
    if has_variable(g, vName)
        x = getfield(g, :values)[vName];
    elseif isnothing(defaultValue)
        x = nothing;
    elseif ismissing(defaultValue)
        x = missing;
    elseif defaultValue != :error
        x = defaultValue;
    else
        error("$vName not found in $g");
    end
    return x
end

"""
	$(SIGNATURES)

Set values for a variable. Errors if variable does not exist.
Optional: validates values against meta info.

# Example
```julia
set_values!(g, :x, [1,2,3]);
# This can also be called with dot notation
g.x = [1,2,3];
```
"""
function set_values!(g :: ModelStats{T}, vName :: Symbol, newValues;
    validate :: Bool = true, silent :: Bool = false)  where T
    vMeta = var_meta(g, vName);
    g.values[vName] = promote_new_values(vMeta, newValues);
    validate  &&  validate_variable(g, vName; silent = silent);
end

# Promote new values when possible, so that any Integer can be passed to, say, a `UInt8` field.
promote_new_values(vi :: VarInfo{T}, newValues) where T = newValues;
promote_new_values(vi :: VarInfo{T1}, newValues :: T2) where 
    {T1 <: Number, T2 <: Number} = convert(T1, newValues);
promote_new_values(vi :: VarInfo{<:AbstractArray{T1}}, 
    newValues :: AbstractArray{T2}) where {T1, T2} =
    convert.(T1, newValues);


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
add_variable!(g :: ModelStats{T}, vInfo, newValues) where T = 
    add_variable!(g, VarInfo(vInfo...), newValues);

function add_variable!(g :: ModelStats{T}, vInfo :: VarInfo, newValues) where T
    vName = var_name(vInfo);
    @assert !has_variable(g, vName)  "$vName already exists"
    g.varMeta[vName] = vInfo;
    g.values[vName] = newValues;
end


"""
	$(SIGNATURES)

Delete a variable. Errors if it does not exist.
"""
function delete_variable!(g :: ModelStats{T}, vName :: Symbol) where T
    @assert has_variable(g, vName)  "$vName not found"
    delete!(g.varMeta, vName);
    delete!(g.values, vName);
end


# """
# 	$(SIGNATURES)

# Show a summary table for selected variables and groups. Because each variable can be of a different type, there is no good way of returning a single table as values (without introducing more dependencies that seems optimal).
# """
# function data_table(g :: ModelStats{T}; vars = var_names(g))
#     tbM = fill("", n_groups(g), length(vars) + 1);
    
#     for ig = 1 : n_groups(g)
#         tbM[ig,1] = string(g.groupNames[ig]);
#     end

#     for (j, varName) in enumerate(vars)
#         tbM[:, j+1] = format_values(get_values(g, varName));
#     end
#     return tbM
# end


## ----------  Reductions

"""
	$(SIGNATURES)

Apply a scalar reduction function to all numeric fields in a `Vector` of `ModelStats`.

# Example
```
reduce
```
"""


## ---------  Testing

function make_test_model_stats(T, nVars, rng :: AbstractRNG)
    mMeta = Dict{Symbol, Any}([:test => true]);
    varMeta = make_test_var_infos(nVars, rng);
    values = make_test_values(varMeta, rng);
    gs = ModelStats{T}(mMeta, varMeta, values);
    @assert validate_stats(gs);
    return gs
end


# -------------------
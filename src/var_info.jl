## ---------------  VarInfo

"""
	$(SIGNATURES)

Holds meta information about one variable. `options` holds predefined options and user defined options.
Predefined options are:
- size (required)
- lb, ub
- lbs, ubs
- dimSums
- grandSum

These can be used to check a data matrix.

# Example
```julia
vi = VarInfo{Vector{Int}}(:x, "x stores a Vector of Int"; size = (3,), lb = 0);
eltype(vi) == Int;
```
"""
struct VarInfo{T}
    varName :: Symbol
    description :: String
    options :: Dict{Symbol, Any}
end

"""
	$(SIGNATURES)

Constructor that provides options as keyword arguments.
"""
function VarInfo(vName :: Symbol, vDescr :: AbstractString, T :: DataType; kwargs...)
    d = dict_from_kwargs(; kwargs...);
    if T <: Number
        d[:size] = ();
    end
    return VarInfo{T}(vName, vDescr, d);
end


function dict_from_kwargs(; kwargs...)
    d = Dict{Symbol, Any}();
    for kw in kwargs
        d[kw[1]] = kw[2];
    end
    return d
end

## ----------  Extended Base functions

Base.size(v :: VarInfo{T}) where {T} = get_option(v, :size);
Base.eltype(v :: VarInfo{T}) where {T} = eltype(T);

function Base.isequal(v1 :: VarInfo{T}, v2 :: VarInfo{T}) where {T}
    isEqual = isequal_common(v1, v2)  &&  isequal_options(v1, v2);
    return isEqual
end

Base.show(io :: IO, vi :: VarInfo{T}) where {T} = 
    print(io, "VarInfo for $(vi.varName) of size $(size(vi))");


## -----------  Access

"""
	$(SIGNATURES)

Retrieve an option. Return `nothing` if option not found.
"""
function get_option(vi :: VarInfo{T}, oName :: Symbol) where T
    if has_option(vi, oName)
        o = vi.options[oName];
    else
        o = nothing;
    end
    return o
end

"""
	$(SIGNATURES)

Get multiple options. `nothing` if not found.
"""
function get_options(vi :: VarInfo{T}, oNames) where T
    return [get_option(vi, oName)  for oName in oNames];
end

"""
	$(SIGNATURES)

Does the `VarInfo` have an option?
"""
has_option(vi :: VarInfo{T}, oName :: Symbol) where T =
    haskey(vi.options, oName);


"""
	$(SIGNATURES)

Returns name of the variable.
"""
var_name(v :: VarInfo{T}) where T = v.varName;

"""
	$(SIGNATURES)

Returns description of a variable.
"""
description(v :: VarInfo{T}) where T = v.description;

"""
	$(SIGNATURES)

Returns the bounds of the variable. These are `nothing` if not set.
"""
bounds(v :: VarInfo{T}) where T = get_options(v, (:lb, :ub));

isscalar(vi :: VarInfo{T}) where T =
    T <: Number;

isequal_common(v1 :: VarInfo{T1}, v2 :: VarInfo{T2}) where {T1, T2} = false;

isequal_common(v1 :: VarInfo{T}, v2 :: VarInfo{T}) where T = 
    (var_name(v1) == var_name(v2))  &&
    (size(v1) == size(v2));

isequal_options(v1 :: VarInfo{T}, v2 :: VarInfo{T}) where T = 
    true; # stub +++++


    """
	$(SIGNATURES)

Initialize an array (or scalar) with zeros. If `VarInfo` does not contain size, return empty array.
"""
function init_values(vi :: VarInfo{T}) where T
    if isscalar(vi)
        return zero(T);
    elseif has_option(vi, :size)
        return zeros(eltype(T), size(vi));
    else
        error("Size is required");
        # return Array{T, 1}();
    end
end


## ----------  Checking VarInfo

function check_var_info(vi :: VarInfo{T}; silent :: Bool = true) where T
    isValid = true;
    isValid = isValid  &&  check_bounds(vi; silent = silent);
    isValid = isValid  &&  check_size(vi; silent = silent);
    return isValid
    # more checks +++++    
end

function check_bounds(vi :: VarInfo{T}; silent :: Bool = true) where T
    isValid = true;
    for bnd in (:lb, :ub)
        isValid = isValid  &&  check_one_bound(vi, bnd; silent = silent);
    end
    return isValid
end

function check_one_bound(vi :: VarInfo{T}, bnd :: Symbol; silent :: Bool = true) where T
    isValid = true;
    if has_option(vi, bnd)
        b = get_option(vi, bnd);
        if !isa(b, eltype(T))
            isValid = false;
            !silent  &&  @warn "Invalid eltype of $bnd:  $(typeof(b))"  
        end
    end
    return isValid
end

function check_size(vi :: VarInfo{T}; silent :: Bool = true) where T
    isValid = true;
    if has_option(vi, :size)
        sz = get_option(vi, :size);
        isValid = isValid && isa(sz, Tuple);
        if T <: AbstractArray
            isValid = isValid && (length(sz) == ndims(T));
        end
    else
        error("Size is required");
    end
    return isValid
end

        
## --------------  Checking data

"""
	$(SIGNATURES)

Check an array against the constraints implied by a `ArrayInfo`.

# Arguments
- `silent`: governs whether `@warn` messages are shown.
"""
function check_var(vi :: VarInfo{T},  x :: T2; 
    silent :: Bool = true) where {T, T2}

    if T != T2
        !silent  &&  @warn "Type mismatch: $vi, $T2";
        return false;
    end
    isValid = check_bounds(vi, x; silent = silent)  &&
        check_size(vi, x; silent = silent) &&
        check_dim_sums(vi, x; silent = silent)  &&
        check_grand_sum(vi, x; silent = silent);
    return isValid
end


function check_bounds(vi :: VarInfo{T}, 
    x :: T; 
    silent :: Bool = true) where T

    isValid = true;
    lb, ub = bounds(vi);
    if !isnothing(lb)
        if !all_at_least(x, lb)
            isValid = false;
            silent  ||  @warn "$vi below lower bound";
        end
    end
    if !isnothing(ub)
        if !all_at_most(x, ub)
            isValid = false;
            silent  ||  @warn "$vi above upper bound";
        end
    end
    return isValid
end

function check_size(vi :: VarInfo{T}, x :: T; 
    silent :: Bool = true) where T

    isValid = true;
    if has_option(vi, :size)
        sz = get_option(vi, :size);
        if size(x) != sz
            isValid = false;
            @warn "Wrong size $vi:  $(size(x))";
        end
    else
        error("Size is required");
    end
    return isValid
end

function check_dim_sums(vi :: VarInfo{T}, x :: T; 
    silent :: Bool = true, atol = 1e-6) where T

    has_option(vi, :dimSums)  ||  return true;

    isValid = true;
    for iDim = 1 : ndims(T)
        isValid = isValid  &&  
            check_dim_sum(vi, x, iDim; silent = silent, atol = atol);
    end
    return isValid
end

function check_dim_sum(vi :: VarInfo{T}, x :: T, iDim :: Integer; 
    silent :: Bool = true, atol = 1e-6) where T

    dimSums = get_option(vi, :dimSums);
    if isnothing(dimSums[iDim])
        isValid = true;
    elseif eltype(T) <: Real
        isValid = all(isapprox.(sum(x; dims = iDim), dimSums[iDim], atol = atol));
    elseif eltype(T) <: Integer
        isValid = all(isequal.(sum(x; dims = iDim), dimSums[iDim]));
    end
    return isValid
end

function check_grand_sum(vi :: VarInfo{T}, x :: T; 
    silent :: Bool = true, atol = 1e-6) where T

    has_option(vi, :grandSum)  ||  return true;
    if eltype(T) <: Integer
        isValid = isequal(sum(x), get_option(vi, :grandSum));
    elseif eltype(T) <: Real
        isValid = isapprox(sum(x), get_option(vi, :grandSum), atol = atol);
    else
        isValid = true;
    end
    return isValid
end


## ---------  Testing

make_test_var_infos(rng :: AbstractRNG) = 
    make_test_var_infos(6, rng);

function make_test_var_infos(nVars, rng :: AbstractRNG)
    eltypeV = [Float64, Int, Float32, UInt8, Int16, Float16];
    szV = [(), (3,), (2,3), (4,3,2), (), (2,)];

    varMeta = Dict{Symbol, VarInfo}();
    for iVar = 1 : nVars
        varName = Symbol("var$iVar");
        lb = convert(eltypeV[iVar], iVar);
        ub = convert(eltypeV[iVar], iVar + 5);
        if szV[iVar] == ()
            T = eltypeV[iVar];
        else
            T = Array{eltypeV[iVar], length(szV[iVar])};
        end            
        varMeta[varName] = make_test_var_info(varName, T, rng);
    end
    return varMeta
end

"""
	$(SIGNATURES)

Make `VarInfo` for testing.
"""
function make_test_var_info(
        vName :: Symbol, 
        T :: DataType, 
        rng :: AbstractRNG)

    eType = eltype(T);
    iVar = rand(rng, 1 : 30);
    lb = convert(eType, iVar);
    ub = convert(eType, lb + 5);
    if T <: Real
        vi = VarInfo(vName, "Descr $vName", T; lb = lb, ub = ub);
    elseif T <: Array
        N = ndims(T);
        sz = Tuple(rand(rng, 1:5, N));
        vi = VarInfo(vName, "Descr $vName", T; lb = lb, ub = ub, size = sz);
    else
        error("Invalid $T")
    end
    @assert check_var_info(vi; silent = false);
    return vi
end


function make_test_values(d :: Dict{Symbol, VarInfo}, rng :: AbstractRNG)
    values = Dict{Symbol, Any}();
    for (vName, vInfo) in d
        values[vName] = make_test_values(vInfo, rng);
    end
    return values
end


"""
	$(SIGNATURES)

Make values for a `VarInfo` for testing.
"""
function make_test_values(vi :: VarInfo{T}, 
    rng :: AbstractRNG) where T

    eType = eltype(T);
    lb = get_option(vi, :lb);
    if isnothing(lb)
        lb = eType(1);
    end
    ub = get_option(vi, :ub);
    if isnothing(ub)
        ub = lb + eType(5);
    end
    if T <: Real
        sz = ();
    else
        sz = get_option(vi, :size);
        if isnothing(sz)
            sz = rand(rng, 1:5, ndims(T)...);
        end
    end

    if eType <: Integer
        # This works for scalars when `sz == ()`
        valueV = rand(rng, lb : ub, sz...);
    elseif eType <: AbstractFloat
        valueV = lb .+ (ub - lb) .* rand(rng, eType, sz...);
    else
        error("Invalid type");
    end
    # Make sure scalars are scalar
    if T <: Real
        valueV = valueV[1];
    end
    # Ensure dim sums
    # Ensure grand sum
    @assert check_var(vi, valueV; silent = false)
    return valueV
end

# --------------
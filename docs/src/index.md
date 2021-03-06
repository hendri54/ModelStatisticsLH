# ModelStatisticsLH

A package that offers containers for storing model generated statistics by group.

## VarInfo

Contains information about a variable:

- name
- description
- data type and size
- optional additional meta info stored as key value pairs

Example:
```julia
vi = VarInfo(:x, "This is x", Vector{Int}; size = (3,), lb = 2);
eltype(vi) == Vector{Int};
size(vi) == (3,);
```

It is possible to add arbitrary user defined objects as long as they support `Base.size`.

```@docs
VarInfo
get_options
get_options
has_option
var_name
description
bounds
init_values
check_var
```

## ModelStats

Holds statistics and meta information.

Values can be accessed and set using dot notation:

```
g.x == get_values(g, :x);
z = g.x[1:2, 3, 4];
g.x = [1,2,3];
g.x[1:2, 3:5] = rand(2,3);
g.x[1:2, 3:5] .= 0.5;
```

```@docs
ModelStats
get_meta
has_variable
n_vars
var_names
var_meta
validate_variable
validate_stats
data_table
add_variable!
delete_variable!
get_values
set_values!
```

## StatsCollection

Container that holds several `ModelStats` objects.

Stats can be accessed by providing "groups" which are the `T` in the `ModelStats{T}` objects. Or they can be accessed as if the `StatsCollection` were a flat collection. 

The user defines `statname_from_name` and `groups_from_name` to translate a variable name of the form (say) `:workTime_gp` into the groups `(:gpa, :parental)` and the variable `:workTime`. Then retrieving `:workTime_gp` is the same as retrieving the `ModelStats{(:gpa, :parental)}` object's `:workTime` variable.

### Example

```julia
sc = StatsCollection{:x}();
# Add the statistics, by group
grp = (:gpa, :parental);
ms = ModelStats{grp}(...);
add_mstats!(sc, ms);
ms == get_mstats(sc, grp);
# Different ways of retrieving stats
x1 = get_stats(sc, grp, :workTime);
x1 == get_stats(sc, :workTime_gp);
x1 == sc.workTime_gp;
# getindex is overloaded
sc.workTime_gp[3] == 0.5;
# setindex is overloaded
sc.workTime_gp[3] = 0.5;
# setproperty is overloaded
sc.workTime_gp = newValues;
```

```@docs
StatsCollection
add_mstats!
delete_mstats!
replace_mstats!
get_groups
has_mstats
get_mstats
get_stats
set_stats!
groups_from_name
statname_from_name
```


## Reductions

```@docs
reduce_stats
reduce_one_field
```

---------
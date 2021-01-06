# ModelStatisticsLH

A package that offers containers for storing model generated statistics by group.

## VarInfo

Contains information about a variable:

- name
- description
- data type and size
- optional additional meta info stored as key value pairs

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

---------
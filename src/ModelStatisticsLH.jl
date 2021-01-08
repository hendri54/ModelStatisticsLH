module ModelStatisticsLH

using DocStringExtensions, Random
using CommonLH

export VarInfo, fraction_info, share_info, check_var_info, check_var
export get_option, get_options, bounds, isscalar, var_name
export make_test_var_info, make_test_var_infos, make_test_values

export ModelStats
export n_vars, var_names, var_meta, get_meta
export make_test_model_stats, validate_stats, data_table
export has_variable, add_variable!, delete_variable!, get_values, set_values!

export StatsCollection
export add_mstats!, delete_mstats!, replace_mstats!
export get_groups, has_mstats, get_mstats, get_stats, set_stats!
export groups_from_name, statname_from_name
export make_test_scollection

include("var_info.jl");
include("group_stats.jl");
include("stats_collection.jl");


format_values(v :: Vector{I}) where I <: Integer = 
    string.(v);

format_values(v :: Vector{R}) where R <: Real = 
    string.(round.(v; digits = 2));

format_values(v) = string.(v);


end #module
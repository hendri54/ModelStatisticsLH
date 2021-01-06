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

include("var_info.jl");
include("group_stats.jl");



format_values(v :: Vector{I}) where I <: Integer = 
    string.(v);

format_values(v :: Vector{R}) where R <: Real = 
    string.(round.(v; digits = 2));

format_values(v) = string.(v);


end #module
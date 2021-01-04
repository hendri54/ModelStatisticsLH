using ModelStatisticsLH
using Test, Random

GS = ModelStatisticsLH;


@testset "All" begin
    include("var_info_test.jl")
    include("group_stats_test.jl");
end

# -----------
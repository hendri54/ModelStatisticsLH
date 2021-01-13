using ModelStatisticsLH, Random, Test

ms = ModelStatisticsLH;


reduceFct(x :: Vector{T}) where T <: AbstractFloat = 
    T(sum(x) / length(x));
reduceFct(x :: Vector{T}) where T <: Integer =
    round(T, sum(x) / length(x));


function reduce_one_test()
    rng = MersenneTwister(123);
    @testset "Reduce one field" begin
        n = 5;
        statV = [ms.make_test_model_stats(:x, 4, rng)  for j = 1 : n];
        varNameV = var_names(statV[1]);
        for varName in varNameV
            xMean = reduce_one_field(statV, varName, reduceFct);
            if !isnothing(xMean)
                @test typeof(xMean) == typeof(get_values(statV[1], varName));
            end
        end
	end
end


function reduce_stats_test()
    rng = MersenneTwister(43);
    @testset "reduce stats" begin
        n = 3;
        scV = [ms.make_test_scollection(:x, rng)  for j = 1 : n];
        sc = reduce_stats(scV, reduceFct);
        @test isequal(get_groups(sc), get_groups(scV[1]));

        for grp in get_groups(sc)
            mStats = get_mstats(sc, grp);
            varNameV = var_names(mStats);
            mStatsV = [get_mstats(scV[j], grp)  for j = 1 : n];
            for varName in varNameV
                # valueV = [get_stats(mStatsV[j], varName)  for j = 1 : n];
                xr = reduce_one_field(mStatsV, varName, reduceFct);
                xr2 = get_stats(sc, grp, varName);
                if isnothing(xr)
                    @test isnothing(xr2)
                elseif xr isa Array
                    for j in eachindex(xr)
                        @test isapprox(xr[j], xr2[j])
                    end
                else
                    @test isapprox(xr, xr2)
                end
            end
        end
	end
end


@testset "Reductions" begin
    reduce_one_test();
    reduce_stats_test();
end

# -----------
using Random, Test
using ModelStatisticsLH

## --------------   Setup

function split_sname(statName :: Symbol)
    return split(string(statName), "_");
end

function ModelStatisticsLH.groups_from_name(m :: StatsCollection{:g}, 
    statName :: Symbol)

    v = split_sname(statName);
    return Symbol(v[2])
end

function ModelStatisticsLH.statname_from_name(m :: StatsCollection{:g}, 
    statName :: Symbol)

    v = split_sname(statName);
    return Symbol(v[1])
end

function scollection_test()
    rng = MersenneTwister(434);

    @testset "StatsCollection" begin
        T = :g;
        sc = StatsCollection{T}();
        @test groups_from_name(sc, :workTime_xy) == :xy
        @test statname_from_name(sc, :workTime_g) == :workTime

        TMS = :tms;
        ms = make_test_model_stats(TMS, 5, rng);
        add_mstats!(sc, ms);
        @test has_mstats(sc, TMS)
        ms2 = get_mstats(sc, TMS);
        @test sort(collect(var_names(ms))) == sort(collect(var_names(ms2)))

        TMS3 = (:tms,:three);
        ms3 = make_test_model_stats(TMS3, 4, rng);
        add_mstats!(sc, ms3);
        @test has_mstats(sc, TMS3);
        ms4 = make_test_model_stats(TMS3, 3, rng);
        replace_mstats!(sc, ms4);
        ms4a = get_mstats(sc, TMS3);
        @test sort(collect(var_names(ms4))) == sort(collect(var_names(ms4a)))

        grpV = get_groups(sc);
        @test length(grpV) == 2

        delete_mstats!(sc, TMS);
        @test !has_mstats(sc, TMS)
	end
end


function get_stats_test()
    rng = MersenneTwister(43);
    @testset "Access stats directly" begin
        T = :g;
        sc = make_test_scollection(T, rng);
        grpV = collect(get_groups(sc));
        grp = grpV[2];
        ms = get_mstats(sc, grp);
        for varName in var_names(ms)
            x = get_stats(sc, grp, varName);
            @test isequal(x, getproperty(ms, varName))

            # Test syntactic sugar
            statName = Symbol("$(varName)_$(grp)");
            @test isequal(x, get_stats(sc, statName))

            if isa(x, AbstractVector)
                idx = length(x);
            elseif isa(x, AbstractMatrix)
                idx = [1, size(x, 2)];
            else
                idx = nothing;
            end
            if !isnothing(idx)
                x2 = getindex(sc, statName, idx...);
                @test isequal(x[idx...], x2)
            end
        end
    end
end


function dot_notation_test()
    rng = MersenneTwister(434);
    @testset "Dot notation" begin
        varName = :x1;
        varMeta = VarInfo(varName, "x1", Matrix{Float64}; size = (4,3));
        xValues = rand(rng, size(varMeta)...);
        @test size(xValues) == (4,3)
        mMeta = Dict{Symbol, Any}([:test => true]);
        grp = :xy;
        statName = :x1_xy;
        ms = ModelStats{grp}(mMeta);
        add_variable!(ms, varMeta, xValues);

        T = :g;
        sc = StatsCollection{T}();
        add_mstats!(sc, ms);

        x = get_stats(sc, statName);
        @test x == xValues
        x2 = sc.x1_xy;
        @test x == x2

        # setstats!
        set_stats!(sc, :x1_xy, x .+ 1);
        @test all(sc.x1_xy .== x .+ 1);
        sc.x1_xy = xValues;
        @test all(sc.x1_xy .== xValues);

        # getindex
        sc.x1_xy .= xValues;
        @test sc.x1_xy[2,3] == xValues[2,3]
        @test sc.x1_xy[3] == xValues[3]
        @test sc.x1_xy[:,2] == xValues[:,2]

        # setstats!
        newValues = xValues .+ 0.5;
        set_stats!(sc, grp, varName, newValues);
        x3 = get_stats(sc, statName);
        @test isapprox(newValues, x3)

        # setindex!
        sc.x1_xy .= xValues;
        sc.x1_xy[3,2] = 17.0;
        @test sc.x1_xy[3,2] == 17.0
        @test sc.x1_xy[2,2] == xValues[2,2];
        sc.x1_xy[:,2] .= 17.0;
        @test all(sc.x1_xy[:,2] .== 17.0)
        @test sc.x1_xy[:,1] == xValues[:,1];
    end
end


@testset "StatsCollection" begin
    scollection_test();
    get_stats_test();
    dot_notation_test();
end

# ------------
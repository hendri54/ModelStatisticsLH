function var_info_test(T)
    rng = MersenneTwister(123);
    @testset "VarInfo $T" begin
        vi = make_test_var_info(:x, T, nothing, rng);
        x = make_test_values(vi, rng);
        @test check_var(vi, x; silent = false)
        lb, ub = bounds(vi);
        @test lb == get_option(vi, :lb);
        @test ub == get_option(vi, :ub);

        vi2 = deepcopy(vi);
        @test isequal(vi, vi2)

        vType = eltype(x);
        if isscalar(vi)
            x2 = ub + one(vType);
        else
            x2 = copy(x);
            x2[1] = ub + one(vType);
        end
        @test !check_var(vi, x2; silent = true)

        # Test grandSum +++++

        # Test dimSums +++++

        # x2 = copy(x);
        # x2[2,1] = ubs[2,1] + T(1e-5);
        # @test !var_check(vi, x2; silent = true)

        # @test !var_check(vi, zeros(Float16, sz...))
    end
end


# function frac_info_test(T)
#     @testset "Fractions" begin
#         rng = MersenneTwister(12);
#         sz = (4,3);
#         vi = fraction_info(:x, "x", T, sz);
#         x = rand(rng, T, sz...);
#         @test var_check(vi, x; silent = false);
#         x[3] = T(1.0 + 1e-5);
#         @test !var_check(vi, x)
#     end
# end


# function share_info_test(T)
#     @testset "Shares" begin
#         rng = MersenneTwister(12);
#         sz = (4,3);
#         vi = share_info(:x, "x", T, sz);
#         x = rand(rng, T, sz...);
#         @test !var_check(vi, x);
#         @test var_check(vi, x ./ sum(x))
#     end
# end


@testset "All" begin
    for T in (Float64, Vector{Float32}, Matrix{Int}, UInt8)
        var_info_test(T);
        # frac_info_test(T);
        # share_info_test(T);
    end
    # gs_basics_test();
end

# ----------
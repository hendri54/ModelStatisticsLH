using Random, Test
using ModelStatisticsLH

## ---------  Setup

# User defined struct to store
mutable struct TestStruct
    x
    y
    z
end

Base.size(TestStruct) = ();
Base.length(TestStruct) = 1;
Base.isequal(t1 :: TestStruct, t2 :: TestStruct) = 
    (t1.x == t2.x) && (t1.y == t2.y) && (t1.z == t2.z);

function constructors_test()
    rng = MersenneTwister(434);
    @testset "Constructors" begin
        T = (:x, :y);
        ms = ModelStats{T}();
        @test n_vars(ms) == 0

        mMeta = Dict{Symbol, Any}([:test => true]);
        ms = ModelStats{T}(mMeta);
        @test n_vars(ms) == 0
        @test get_meta(ms, :test) == true

        vInfoV = make_test_var_infos(rng);
        nVars = length(vInfoV);
        ms = ModelStats{T}(mMeta, vInfoV);
        @test n_vars(ms) == nVars

        # Vector of VarInfo as input
        viV = Vector{VarInfo}();
        for (vName, vi) in vInfoV
            push!(viV, vi);
        end
        ms = ModelStats{T}(mMeta, viV);
        @test n_vars(ms) == nVars
    end
end

function retrieve_test()
    rng = MersenneTwister(434);
    @testset "Retrieve" begin
        nVars = 6;
        ms = make_test_model_stats(:test, nVars, rng);
        @test nVars == n_vars(ms)
        varNames = var_names(ms);
        @test length(varNames) == nVars

        for varName in varNames
            @test has_variable(ms, varName)
            vm = var_meta(ms, varName);
            @test eltype(ms, varName) == eltype(vm)
            @test var_name(vm) == varName
            valueV = getproperty(ms, varName);
            value2V = get_values(ms, varName);
            @test valueV == value2V;
            @test check_var(vm, valueV; silent = false);

            # Set values
            value3V = make_test_values(vm, rng);
            @test size(value3V) == size(valueV)
            @test check_var(vm, value3V; silent = false);
            set_values!(ms, varName, value3V);
            valueV = get_values(ms, varName);
            @test isequal(valueV, value3V);

            # Test dot notation
            if varName == :var1
                valueV = get_values(ms, varName);
                value2V = ms.var1;
                @test isequal(valueV, value2V);
                T = eltype(valueV);
                value3V = value2V .+ one(T);
                ms.var1 = value3V;
                @test ms.var1 == value3V
            end
        end
        # @test validate_stats(ms)

        # tbM = data_table(ms);
        # @test isa(tbM, Matrix{String}) 
        # @test isequal(tbM, ["g1" "1.0" "2" "3.0" "4"; "g2" "3.5" "4" "5.5" "6"; "g3" "6.0" "7" "8.0" "9"])
        # println(tbM);

        varName = :new1;
        @test !has_variable(ms, varName)
        @test get_values(ms, varName; defaultValue = 1) == 1
        newValueV = 12 .+ (1 : 4);
        vInfo = VarInfo(:new1, "new variable", eltype(newValueV); 
            lb = 10, ub = 20, size = size(newValueV));
        @test check_var_info(vInfo; silent = false);
        add_variable!(ms, vInfo, newValueV);
        @test n_vars(ms) == nVars + 1
        @test has_variable(ms, varName)
        valueV = get_values(ms, varName)
        @test isequal(valueV, newValueV)
        # @test isequal(get_value(ms, varName, 2), valueV[2])

        # varName = :new2
        # add_variable!(ms, (varName, 7, 43, "Description $varName"), newValueV);
        # valueV = get_values(ms, varName);
        # @test isequal(valueV, newValueV)

        delete_variable!(ms, varName);
        @test !has_variable(ms, varName)
        @test n_vars(ms) == nVars 
    end
end

function getindex_test()
    rng = MersenneTwister(434);
	@testset "getindex and setindex" begin
        nVars = 3;
        ms = make_test_model_stats(:test, nVars, rng);

        varName = :new1;
        newValueV = rand(rng, 4,3,2);
        vInfo = VarInfo(varName, string(varName), eltype(newValueV); 
            size = size(newValueV));
        @test check_var_info(vInfo; silent = false);
        add_variable!(ms, vInfo, newValueV);
        @test ms.new1[2:3, 1:2, 1] == newValueV[2:3, 1:2, 1]

        ms.new1[3,2,2] = 0.2;
        @test ms.new1[3,2,2] == 0.2;
        ms.new1[2:3, 1:2, 1] .= 0.3;
        @test all(ms.new1[2:3, 1:2, 1] .== 0.3);
        x = rand(rng, 2, 2);
        ms.new1[2:3, 1:2, 1] .= x;
        @test all(ms.new1[2:3, 1:2, 1] .== x)
    end
end

function struct_test()
    rng = MersenneTwister(434);
    @testset "Arbitrary structs" begin
        nVars = 3;
        ms = make_test_model_stats(:test, nVars, rng);

        varName = :new1;
        newValueV = TestStruct(1, 2, 3);
        vInfo = VarInfo(varName, string(varName), TestStruct; 
            size = size(newValueV));
        @test check_var_info(vInfo; silent = false);
        add_variable!(ms, vInfo, newValueV);
        @test ms.new1 == newValueV

        newValueV = TestStruct(4,5,6);
        ms.new1 = newValueV;
        @test ms.new1 == newValueV;

        varName = :new2;
        newValueV = [TestStruct(1,2,3), TestStruct(2,3,4)];
        vInfo = VarInfo(varName, string(varName), Vector{TestStruct}; 
            size = size(newValueV));
        @test check_var_info(vInfo; silent = false);
        add_variable!(ms, vInfo, newValueV);
        @test all(ms.new2 .== newValueV)
    end
end


@testset "ModelStats" begin
    constructors_test();
    retrieve_test();
    getindex_test();
    struct_test();
end

# ------------
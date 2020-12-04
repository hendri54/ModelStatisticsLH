using ModelStatisticsLH
using Test

GS = ModelStatisticsLH;

function var_info_test()
    @testset "VarInfo" begin
        vi = VarInfo(:x, 0.0, 1.0);
        println(vi);
        @test eltype(vi) == Float64
    end
end

function gs_basics_test()
    @testset "Basics" begin
        ng = 3;
        grNames = [Symbol("g$j")  for j = 1 : ng];

        # Build the GroupStats 
        eltypeV = [Float64, Int, Float32, UInt8];
        nVars = length(eltypeV);
        varNames = [Symbol("v$j")  for j = 1 : nVars];
        varMeta = Vector{VarInfo}(undef, nVars);
        for iVar = 1 : nVars
            lb = convert(eltypeV[iVar], iVar);
            ub = convert(eltypeV[iVar], iVar + 5);
            varMeta[iVar] = VarInfo(varNames[iVar], lb, ub);
        end
        gs = GroupStats(grNames, varMeta);
        println(gs);

        @test n_groups(gs) == length(grNames)

        # Fill in values
        for iVar = 1 : nVars
            varName = varNames[iVar];
            @test eltype(gs, varName) == eltypeV[iVar]
            @test has_variable(gs, varName)

            vm = get_meta(gs, varName);
            @test vm.varName == varName
            
            valueV = LinRange(vm.lb, vm.ub, ng);
            if eltypeV[iVar] <: Integer
                valueV = round.(eltypeV[iVar], valueV);
            end
            GS.set_values!(gs, varName, valueV);
            value2V = get_values(gs, varName);
            @test isequal(valueV, value2V)
        end
        @test validate_stats(gs)

        tbM = data_table(gs);
        @test isa(tbM, Matrix{String}) 
        @test isequal(tbM, ["g1" "1.0" "2" "3.0" "4"; "g2" "3.5" "4" "5.5" "6"; "g3" "6.0" "7" "8.0" "9"])
        println(tbM);

        varName = :new1;
        @test !has_variable(gs, varName)
        vInfo = VarInfo(:new1, 10, 20);
        newValueV = 12 .+ (1 : ng);
        add_variable!(gs, vInfo, newValueV);
        @test has_variable(gs, varName)
        valueV = get_values(gs, varName)
        @test isequal(valueV, newValueV)

        varName = :new2
        add_variable!(gs, (varName, 7, 43, "Description $varName"), newValueV);
        valueV = get_values(gs, varName);
        @test isequal(valueV, newValueV)

        delete_variable!(gs, varName);
        @test !has_variable(gs, varName)
    end
end


@testset "All" begin
    var_info_test();
    gs_basics_test();
end

# -----------
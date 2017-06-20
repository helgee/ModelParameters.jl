using ModelParameters
using Base.Test

struct TestStruct{T<:Number}
    x::T
end

struct TestStruct2{T<:Number}
    x::T
    y::T
end

@testset "ModelParameters" begin
    @testset "Parameters" begin
        @test_throws ArgumentError Parameter(0.0, 1.0, -1.0)
        @test_throws ArgumentError Parameter(-2.0, -1.0, 1.0)
        p = Parameter(0.0)
        @test lower(p) == -Inf
        @test upper(p) == Inf
        p = Parameter(0)
        @test lower(p) == typemin(Int)
        @test upper(p) == typemax(Int)
        p = Parameter(-1.0, 1.0)
        @test initial(p) == 0.0
        @test isparameter(p)
        c = constant(1.0)
        @test !isparameter(c)
        @test isfixed(c)
        @test_throws ArgumentError push!(p, 3.0)
        @test_throws ArgumentError push!(p, -3.0)
        push!(p, 0.5)
        @test p == 0.5
        @test p ≈ 0.5
        reset!(p)
        @test 0 == p
        @test 0 ≈ p
        arr = [p, 1.0]
        @test isparameter.(arr) == [true, false]
        @test value.(arr) == [0.0, 1.0]
        @test getparameters(p) == [p]
        @test getparameters(c) == Parameter[]
        @test getparameters(arr) == [p]
        @test getparameters([Nullable(p), Nullable(c)]) == [p]
        @test arr ≈ arr

        p = one(p)
        @test norm(p) == value(p)
        @test imag(p) == 0im
        @test isequal(1.0, p)
        @test isequal(p, 1.0)
        @test isapprox(p, p)
        @test isapprox(1.0, p)
        @test zero(p) == 0.0

        p = Parameter(0.0)
        @test string(p) == "-Inf ≤ 0.0 ≤ Inf"
        @test string(c) == "1.0"

        @test c + c == 2
        @test c - c == 0
        @test c * c == 1
        @test c / c == 1

        @test c + 1 == 2
        @test c - 1 == 0
        @test c * 1 == 1
        @test c / 1 == 1
        @test 1 + c == 2
        @test 1 - c == 0
        @test 1 * c == 1
        @test 1 / c == 1

        a = [1.0, 2.0]
        @test c + a == [2.0, 3.0]
        @test c - a == [0.0, -1.0]
        @test c * a == [1.0, 2.0]
        @test a + c == [2.0, 3.0]
        @test a - c == [0.0, 1.0]
        @test a * c == [1.0, 2.0]
        @test a / c == [1.0, 2.0]
        @test isequal(p,p)
        @test !isequal(p,c)

        @test arr+3 == [3.0, 4.0]
        @test 3+arr == [3.0, 4.0]
        @test arr-3 == [-3.0, -2.0]
        @test 3-arr == [3.0, 2.0]
        @test arr*3 == [0.0, 3.0]
        @test 3*arr == [0.0, 3.0]
        @test arr/3 == [0.0, 1/3.0]
        @test p < c
        @test c > p
        @test -1 < c
        @test c < 3
        @test c > -1
        @test 3 > c

        @test [c, c] + [c, c] == [1, 1] + [1, 1]
        @test [1, 1] + [c, c] == [1, 1] + [1, 1]
        @test [c, c] + [1, 1] == [1, 1] + [1, 1]
        @test [c, c] - [c, c] == [1, 1] - [1, 1]
        @test [1, 1] - [c, c] == [1, 1] - [1, 1]
        @test [c, c] - [1, 1] == [1, 1] - [1, 1]

        @test [c, c] .* [c, c] == [1, 1] .* [1, 1]
        @test [1, 1] .* [c, c] == [1, 1] .* [1, 1]
        @test [c, c] .* [1, 1] == [1, 1] .* [1, 1]
        @test [c, c] ./ [c, c] == [1, 1] ./ [1, 1]
        @test [1, 1] ./ [c, c] == [1, 1] ./ [1, 1]
        @test [c, c] ./ [1, 1] == [1, 1] ./ [1, 1]

        p = Parameter(0.0)
        const fun = (
            :abs2, :acosh, :acot, :acotd, :acoth, :acsc, :acscd, :acsch, :asec,
            :asecd, :asinh, :atan, :atand, :cbrt, :cos, :cosd, :cosh, :cot, :cotd,
            :coth, :csc, :cscd, :csch, :exp, :exp2, :expm1, :gamma, :inv, :lgamma,
            :log, :log10, :log1p, :log2, :sec, :secd, :sech, :sin, :sind, :sinh,
            :sqrt, :tan, :tand, :tanh,
        )
        const fun2 = (:acos, :acosd, :asech, :asin, :asind, :atanh)
        val = pi/2
        push!(p, val)
        for f in fun
            @eval begin
                @test $f($p) == $f(float($val))
            end
        end
        val = 0.0
        push!(p, val)
        for f in fun2
            @eval begin
                @test $f($p) == $f(float($val))
            end
        end
    end
    @testset "vary" begin
        exp = TestStruct(Parameter(0.5, 0.0, 1.0))
        act = @vary(x >= 0.0, x <= 1.0, x = 0.5, TestStruct(x))
        @test exp.x == act.x
        exp = TestStruct2(Parameter(0.5, 0.0, 1.0), Parameter(0.5, 0.0, 1.0))
        act = @vary(
            x >= 0.0,
            x <= 1.0,
            x = 0.5,
            y >= 0.0,
            y <= 1.0,
            y = 0.5,
            TestStruct2(x, y)
        )
        @test exp.x == act.x
        @test exp.y == act.y
        exp = TestStruct2(Parameter(0.5), Parameter(0.5))
        act = @vary(
            x = 0.5,
            y = 0.5,
            TestStruct2(x, y)
        )
        @test exp.x == act.x
        @test exp.y == act.y
    end
end

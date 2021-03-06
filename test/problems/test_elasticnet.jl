@testset "Elastic net ($T)" for T in [Float32, Float64, ComplexF32, ComplexF64]

    using ProximalOperators
    using ProximalAlgorithms
    using LinearAlgebra
    using Random

    Random.seed!(0)

    # TODO: generate problem with known solution instead

    m, n = 50, 200

    A = randn(T, m, n)
    b = randn(T, m)

    R = real(T)

    reg = ElasticNet(R(1), R(1))
    reg1 = NormL1(R(1))
    reg2 = SqrNormL2(R(1))
    loss = Translate(SqrNormL2(R(1)), -b)

    L = opnorm(A)^2

    x0 = zeros(T, n)
    solver = ProximalAlgorithms.PANOC{R}(tol=eps(R))
    x_panoc, it = solver(x0, f=loss, A=A, g=reg)

    @testset "DavisYin" begin

        x0 = zeros(T, n)
        solver = ProximalAlgorithms.DavisYin{R}(tol=R(1e-6))
        xf_dys, xg_dys, it_dys = solver(
            x0, f=reg1, g=reg2, h=loss, A=A, L=L
        )
        @test eltype(xf_dys) == T
        @test eltype(xg_dys) == T
        @test norm(xf_dys - x_panoc, Inf) <= 1e-3
        @test norm(xg_dys - x_panoc, Inf) <= 1e-3
        @test it_dys <= 1900

        x0 = randn(T, n)
        solver = ProximalAlgorithms.DavisYin{R}(tol=R(1e-6))
        xf_dys, xg_dys, it_dys = solver(
            x0, f=reg1, g=reg2, h=loss, A=A, L=L
        )
        @test eltype(xf_dys) == T
        @test eltype(xg_dys) == T
        @test norm(xf_dys - x_panoc, Inf) <= 1e-3
        @test norm(xg_dys - x_panoc, Inf) <= 1e-3
        @test it_dys <= 2600

    end

    afba_test_params = [
        (R(2), R(0), 230),
        (R(1), R(1), 230),
        (R(0), R(1), 470),
        (R(0), R(0), 500),
        (R(1), R(0), 230)
    ]

    @testset "AFBA" for (theta, mu, maxit) in afba_test_params

        x0 = randn(T, n)
        y0 = randn(T, m)

        solver = ProximalAlgorithms.AFBA{R}(theta=theta, mu=mu, tol=R(1e-6))
        x_afba, y_afba, it_afba = solver(
            x0, y0, f=reg2, g=reg1, h=loss, L=A, betaQ=R(1),
        )
        @test eltype(x_afba) == T
        @test eltype(y_afba) == T
        @test norm(x_afba - x_panoc, Inf) <= 1e-4
        @test it_afba <= maxit

    end
end

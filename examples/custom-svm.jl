"""
    Source code for the example given in custom-svm.md
"""

using Statistics
using DiffOpt
using Flux
using Flux: onecold, binarycrossentropy, throttle, logitcrossentropy, crossentropy
using Base.Iterators: repeated
using JuMP
using SCS
using CSV
using DataFrames
using ChainRulesCore

labels = NaN;   # hack for the SVM

"""
    SVM as a Flux layer
"""
function SVM(X::AbstractMatrix{T}; model = Model(() -> diff_optimizer(SCS.Optimizer))) where {T}
    D, N = size(X)
    
    Y = vec([y >= 0.5 ? 1 : -1 for y in labels]')
    # scale class from 0,1 to -1,1. required for SVM
    
    # model init
    empty!(model)
    set_optimizer_attribute(model, MOI.Silent(), true)
    
    # add variables
    @variable(model, l[1:N])
    @variable(model, w[1:D])
    @variable(model, b)
    
    @constraint(model, cons, Y.*(X'*w .+ b) + l.-1 ∈ MOI.Nonnegatives(N))
    @constraint(model, 1.0*l ∈ MOI.Nonnegatives(N));
    
    @objective(
        model,
        Min,
        sum(l),
    )

    optimize!(model)

    wv = value.(w)
    bv = value(b)
    
    return (X'*wv .+ bv)' #prediction
end

function ChainRulesCore.rrule(::typeof(SVM), X::AbstractArray{T}; model = Model(() -> diff_optimizer(SCS.Optimizer))) where {T}

    predictions = SVM(X, model=model) 
    
    """
        model[:w], model[:b] are the weights of this layer
        they are not updated using backward pass
        since they can be computed to an accurate degree using a solver
    """
    function pullback_SVM(dX)
        dy = zero(dX)   # since w#
        return (NO_FIELDS, dy)
    end
    return predictions, pullback_SVM
end

function fetchProblem(;split_ratio::Float64)
    df = CSV.File("titanic_preprocessed.csv") |> DataFrame

    Y = df[:, 2]
    X = df[!, 3:12]
    X = Matrix(X)'

    D, N = size(X)

    l = Int(floor(length(Y)*split_ratio))
    return X[:, 1:l], X[:, l+1:N], Y[1:l]', Y[l+1:N]'
end
X_train, X_test, Y_train, Y_test = fetchProblem(split_ratio=0.8)
D = size(X_train)[1];

m = Chain(
    Dense(D, 16, relu),
    Dropout(0.5),
    SVM
#     Dense(32, 1, σ),
);

custom_loss(x, y) = logitcrossentropy(m(x), y) 
opt = ADAM(); # popular stochastic gradient descent variant

classify(x::Float64) = (x>=0.5) ? 1 : 0

function accuracy(x, y_true)
    y_pred = classify.(m(x))
    return sum(y_true .≈ y_pred) / length(y_true)
end

dataset = repeated((X_train,Y_train), 1) # repeat the data set, very low accuracy on the orig dataset
evalcb = () -> @show(custom_loss(X_train,Y_train)) # callback to show loss

labels = Y_train   # needed for SVM
for iter in 1:1
    Flux.train!(custom_loss, params(m), dataset, opt, cb = throttle(evalcb, 5)); #took me ~5 minutes to train on CPU
end

@show accuracy(X_train, Y_train)

labels = Y_test   # needed for SVM
@show accuracy(X_test, Y_test)
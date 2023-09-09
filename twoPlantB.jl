using JuMP,HiGHS

##
Products = [:Standard,:Deluxe]
Plants = [:A,:B]
##

##
ProfitMargin = Containers.DenseAxisArray([10,15],Products)

GrindingTime = Containers.DenseAxisArray(
                [4 2;5 3], Plants,Products)
GrindingTimeAvail = Containers.DenseAxisArray([80,60],Plants)

PolishingTime = Containers.DenseAxisArray(
                [2 5;5 6], Plants,Products)
PolishingTimeAvail = Containers.DenseAxisArray([60,75],Plants)

RawMaterialPerUnit = 4
TotalRawMaterial = 120
##

##
model = Model(HiGHS.Optimizer)
##

## 
@variable(model,X[Plants,Products]>=0)
##

##
@constraint(model,cons_grind[i=Plants],
            sum(GrindingTime[i,:] .* X[i,:]) <= GrindingTimeAvail[i])

@constraint(model,cons_polish[i=Plants],
            sum(PolishingTime[i,:] .* X[i,:]) <= PolishingTimeAvail[i])

@constraint(model,cons_raw,
            RawMaterialPerUnit*sum(X) <= TotalRawMaterial)
##

##
@objective(model,Max,
            sum(X[i,j] .* ProfitMargin[j] 
            for i in Plants, j in Products))
##

##
optimize!(model)
##

##
solution_summary(model)
##

##
print(value.(X))
##
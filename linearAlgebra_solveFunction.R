
## linear algebra
#2x + 3y = 10
#4x - 2y = 6

## set up matrix like so for function above
a <- matrix(c(2, 3, 4, -2), nrow = 2, byrow = TRUE)
b <- c(10, 6)

## use solve() function to find x and y
solve(a,b)


## Now 3 variables
#3x + 2y - z = 7
#x - y + 2z = -1
#2x + 3y + 4z = 12

## set up like so
a <- matrix(c(3, 2, -1, 1, -1, 2, 2, 3, 4), nrow = 3, byrow = TRUE)
b <- c(7, -1, 12)

solve(a,b)

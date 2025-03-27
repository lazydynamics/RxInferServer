"""
    @expect expr || default

Evaluates `expr` and returns its value if it's not `nothing`. 
If `expr` evaluates to `nothing`, exits the current function immediately and returns `default`.

This operation is useful to handle errors and return a default value from a function when an unexpected value is encountered.
Might be useful to handle database operations that return `nothing` to indicate an error.

```julia
function update_user(id::String)
    user = @expect __database_op_get_user(id) || return RxInferServerOpenAPI.ErrorResponse(
        error = "Bad Request", message = "Unable to get user due to internal error"
    )

    ## update user here

    return user
end

This function will return an error response if the user is not found.
Otherwise, it will update the user and return the updated user.
```

"""
macro expect(expression::Expr)
    if expression.head != :||
        error("Expected `||` expression in the `@expect` macro, got `$(expression.head)`")
    end

    if length(expression.args) != 2
        error("Expected two arguments in the `@expect` macro, got `$(length(expression.args))`")
    end

    return quote
        result = $(esc(expression.args[1]))
        if isnothing(result)
            return $(esc(expression.args[2]))
        end
        result
    end
end

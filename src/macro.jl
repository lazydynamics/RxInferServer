"""
    @expect expr || default

Evaluates `expr` and returns its value if it's not `nothing`. 
If `expr` evaluates to `nothing`, exits the current function immediately and returns `default`.
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
# Copyright 2015 Garrett Serack (FearTheCowboy)
# Modifications Copyright 2016 Philipp Serr (episource)
#  - convert to powershell module


# ---------------------------------------------------------------------------
# Name:   Invoke-Assignment
# Alias:  =
# Author: Garrett Serack (@FearTheCowboy)
#         http://fearthecowboy.com/powershell/2015/12/11/PowerShell-A-Better-Ternary/
# Desc:   Enables expressions like the C# operators: 
#         Ternary: 
#             <condition> ? <trueresult> : <falseresult> 
#             e.g. 
#                status = (age > 50) ? "old" : "young";
#         Null-Coalescing 
#             <value> ?? <value-if-value-is-null>
#             e.g.
#                name = GetName() ?? "No Name";
# 			  
# Ternary Usage:  
#         $status == ($age > 50) ? "old" : "young"
#
# Null Coalescing Usage:
#         $name == (get-name) ?? "No Name" 
# ---------------------------------------------------------------------------

# returns the evaluated value of the parameter passed in, 
# executing it, if it is a scriptblock   
function eval($item) {
    if( $item -ne $null ) {
        if( $item -is "ScriptBlock" ) {
            return & $item
        }
        return $item
    }
    return $null
}

# an extended assignment function; implements logic for Ternarys and Null-Coalescing expressions
function Invoke-Assignment {
    if( $args ) {
        # ternary
        if ($p = [array]::IndexOf($args,'?' )+1) {
            if (eval($args[0])) {
                return eval($args[$p])
            } 
            return eval($args[([array]::IndexOf($args,':',$p))+1]) 
        }
        
        # null-coalescing
        if ($p = ([array]::IndexOf($args,'??',$p)+1)) {
            if ($result = eval($args[0])) {
                return $result
            } 
            return eval($args[$p])
        } 
        
        # neither ternary or null-coalescing, just a value  
        return eval($args[0])
    }
    return $null
}

# alias the function to the equals sign (which doesn't impede the normal use of = )
Set-Alias = Invoke-Assignment
Export-ModuleMember -Function Invoke-Assignment -Alias *
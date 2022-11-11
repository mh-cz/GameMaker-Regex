# Gamemaker Regular Expression
A pretty readable RegEx made in GM for GM 2.3+  
Suitable for quick searches or string validations  
  
Expressions can be written in two modes: *exact* and *simple*  
  
## What can it do?
`gmre_match(ex, string)` -> bool  
`gmre_find(ex, str, substr)` -> string  
`gmre_find_all(ex, str, substr)` -> array of strings  
`gmre_find_pos(ex, str, substr)` -> real  
`gmre_find_pos_all(ex, str, substr)` -> array of reals  
`gmre_replace(ex, str, substr)` -> string  
`gmre_replace_all(ex, str, substr_or_array)` -> string  
`gmre_contains(ex, str, substr)` -> bool  

## How do I use it?
`simple - bool (optional)`  
  
Creating an expression:  
`var ex1 = new expression(expr_string, simple*);`  
`var ex2 = new expression(expr_string, simple*);`  
`var ex3 = new expression(expr_string, simple*);`  
  
Using an expression:  
`var result1 = gmre_*(ex1, string, ...)`  
`var result2 = gmre_*(ex2, string, ...)`  
`var result3 = gmre_*(ex3, string, ...)`  
  
Editing an existing expression  
`gmre_ex_parse(ex, new_expr_string, simple*)`  
  
## Rules
The entire system works around rules  
There are 3 types of rules: charset `[]`, string `||`, loop `()` + position subrule `{}`  
Each rule can be negated, chained using repeats and can have a position subrule added to it  
  
Spaces between rules are allowed **except** between *rule and repeat* and *negation and rule*  
  
`* - optional`  
`<negation>* <rule> <repeats>* <pos>*`  
  
### Charset	rule
`[]` Any characters  
`[xyz]` Characters "x","y" and "z"  
`[x-y]` Char range from "x" to "y"  
`[x-yz]` Char range from "x" to "y" + character "z"  
`[xy ]` Characters "x","y" and " " (space)  
  
Range:  
Only works for basic alphabet `A-Z` `a-z` and numbers `0-9`
`x-y` Lowercase only  
`X-Y` Uppercase only  
`X-y` or `x-Y` Both lowercase and uppercase are allowed (case insensitive)  

### String rule
`|x|` String "x"  
`|x z|` String "x z"  
`|xYz|` String "xYz"  
  
### Loop rule
Loop **cannot** contain another loop  
`()` Empty loop  
`(|x|[y-z])` Loop containing a string rule and a charset rule  

### Position subrule
This subrule cannot be alone  
Having loop rules inside isn't supported  
`<rule> {x=|a|}` The xth character of the rule on the left must be equal to the rule `|a|`  
`<rule> {x=|a|,[b]}` The xth character of the rule on the left must be equal to the rule `|a|` **OR** to the rule `[b]`  
`<rule> {x,y=[a],|b|}` The xth character **AND** the yth character of the rule on the left must be equal to the rule `[a]` **OR** to the rule `|b|`  

The lowercase "n" stands for the last character and `+` or `-` can be added to it to add or subtract a number from this position  
`<rule> {n=|a|}` The last character of the rule on the left must be equal to the rule `|a|`  
`<rule> {n-1=|a|}` The penultimate character of the rule on the left must be equal to the rule `|a|`  
  
Rules can be also used to find a position and `+` or `-` can be added to it to add or subtract a number from this position  
`<rule> {[a]+1=[b]}` All positions of characters that meet the condition of the rule `[a]`+1 must be equal to the rule `|b|`  
`<rule> {[a]-1,|b|+2=[b],|c|}` Positions of `[a]`-1 **AND** `|b|`+2 must be equal to rules `[b]` **OR** `|c|`  

# Cheat sheet
![gmre](https://user-images.githubusercontent.com/68820052/201385231-ae57f772-6879-4771-ac45-23c4c25d38a6.png)



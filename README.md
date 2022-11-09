# Gamemaker Regular Expression
A somewhat readable RegEx made in GM for GM 2.3+  
Suitable for quick searches or string validations  
  
Expressions can be written in two modes: *exact* and *simple*  
  
## Rules
The entire system works around rules  
There are 3 types of rules: charset `[]`, string `||`, loop `()` + position subrule `{}`  
Each rule can be negated, chained using repeats and can have a position subrule added to it  
  
Spaces between rules are allowed but not between *rule and repeat* and *negation and rule*  
  
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




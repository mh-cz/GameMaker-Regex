# Gamemaker Regular Expression
My custom and pretty readable version of a RegEx like string manipulator made in GM for GM 2.3+  
Suitable for quick searches or string validations  
  
Expressions can be written in two modes: *exact* and *simple*  
  
## What can it do?
- Match  
`gmre_match(ex, string)` -> bool  
- Find  
`gmre_find(ex, str)` -> string  
- Find all  
`gmre_find_all(ex, str)` -> array of strings  
- Find position  
`gmre_find_pos(ex, str)` -> real  
- Find all positions  
`gmre_find_pos_all(ex, str)` -> array of reals  
- Replace  
`gmre_replace(ex, str, substr)` -> string  
- Replace all  
`gmre_replace_all(ex, str, substr_or_array)` -> string  
- Check if contains  
`gmre_contains(ex, str)` -> bool  
- Split  
`gmre_split(ex, str)` -> array of strings  
  
## How do I use it?
`simple - bool (optional, default: false)`  
  
Creating an expression:  
`var ex1 = new gmre_ex(expr_string, simple*);`  
`var ex2 = new gmre_ex(expr_string, simple*);`  
`var ex3 = new gmre_ex(expr_string, simple*);`  
  
Using an expression:  
`var result1 = gmre_*(ex1, string, ...)`  
`var result2 = gmre_*(ex2, string, ...)`  
`var result3 = gmre_*(ex3, string, ...)`  
  
Editing an existing expression  
`gmre_ex_parse(ex, new_expr_string, simple*)`  
  
You can check if the expression was parsed successfully with variable `ex.ok`  
If `ex.ok` returns `false` you can show the error message using variable `ex.err` which returns a string that will tell you what and where it went wrong  
  
## Rules
The entire system works around rules  
There are 3 types of rules: charset `[]`, string `||`, loop `()` + position subrule `{}`  
Each rule can be negated, chained using repeats and can have a position subrule added to it  
  
Spaces between rules are allowed **except** between *>rule and repeat<* and *>negation and rule<*  
  
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
  
## Good-to-know stuff
You can simply do `var result = gmre_do_something(new gmre_ex(...), ...)` but it's always faster to create expressions in the Create event so you don't parse rules AND process strings at the same time (like every step)  
`[a][b][c]` is the same as `|abc|`  
A rule with min 0 repeats isn't mandatory: `[a][b]0-2[c]` matches with "abc", "abbc" and also "ac"  
Characters used for parsing rules `[ ] { } ( ) |` inside charsets/strings require `\` before them to prevent parsing mistakes -> `[A-z0-9\[\]\{\}\|]`, `|abc\(d\)efg|`
  
# Examples
### Email validator 
With all valid special characters according to this site: https://help.returnpath.com/hc/en-us/articles/220560587-What-are-the-rules-for-email-address-syntax-  
Create:  
```
mval_str = "[A-z0-9.!#$%&'*+-/=?^_`\{\|]1-64 {1,n,[.!#$%&'*+-/=?^_`\{\|]+1=![.!#$%&'*+-/=?^_`\{\|]} |@| ([A-z0-9-]1-40{1,n=![-]}|.|)1-4 [A-z0-9-]1-10 {1,n=![-]}";
ex_mail_validator = new gmre_ex(mval_str);
```
Step or whatever:  
```
var is_valid = gmre_match(ex_mail_validator, "some.name@domain.net");
```  
`is_valid = true`  
  
### String splitter
Create:  
```
ex_split_spaces = new gmre_ex("| |"); // or in simple syntax: new gmre_ex(" ", true);
```
Step or whatever:  
```
var split_arr = gmre_split(ex_split_spaces, "blah blah blah");
```
`split_arr = ["blah", "blah", "blah"]`  
  
### Inventory search
In simple mode  
<sup>You can get Foreach for GM [here](https://github.com/mh-cz/GameMaker-Foreach) ;)</sup>  
Create:   
```
inventory = ["pickaxe", "axe", "red potion", "blue potion"]
ex_inv_search = new gmre_ex();
found_results = [];
```
Step or whatever:  
```
if keyboard_check_released(vk_anykey) {
	gmre_ex_parse(ex_inv_search, <some_keyboard_input>, true);
	found_results = [];
	foreach item in inventory exec {
		var cont = gmre_contains(ex_inv_search, item);
		if cont array_push(found_results, item);
	}
}
```
`found_results = ["pickaxe", "axe"]` if `some_keyboard_input = "axe"`  
`found_results = ["pickaxe", "red potion", "blue potion"]` if `some_keyboard_input = "p"`  
`found_results = ["red potion", "blue potion"]` if `some_keyboard_input = "pot"`  
  
# Cheat sheet
![gmre](https://user-images.githubusercontent.com/68820052/201469874-6cc5c226-f2d6-48c5-856c-46a6be4da779.png)




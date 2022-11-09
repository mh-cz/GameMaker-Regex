# Gamemaker Regular Expression
A somewhat readable RegEx made in GM for GM 2.3+  
Suitable for quick searches or string validations  
  
Expressions can be written in two modes: *exact* and *simple*  
  
### Rules
The entire system works around rules  
There are 4 types of rules: charset `[]`, string `||`, loop `()` and custom position `{}`  
Each rule can be negated, chained using repeats and can have a custom position subrule for futher specs added to it  

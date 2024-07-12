```nushell
> 'a' | str append 'b'
ab
> 'a' | str append 'b' --concatenator '*'
a*b
> 'a' | str append 'b' --concatenator '*' --new-line 
a
*b
> 'a' | str append 'b' --concatenator '***'
a***b
> 'a' | str append 'b' --new-line 
a
b
> 'a' | str append 'b' --tab
ab
> 'a' | str append 'b' --space 
a b
```

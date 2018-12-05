---
layout: doc
title: "Advanced C"
learning_objectives:
  - Implementing an object with blocks
  - Understanding extensions to the C language
  - Exploring modern syntax structures in C
---

Welcome to the first CS296 assignment! Before we begin, let's go through a quick
overview of the structure of this document. Each document for CS2916-41 will
have the following sections:

+ Introduction - a quick blurb providing some motivation behind the MP
+ Requirements - the minimum requirements you will need to satisfy to get a full
  score on the MP
+ Walkthrough - this may not be in every document, but for some assignments, we
  will include a 'walkthrough' section that will have more hints on how to
  complete the assignment.
+ Analysis - a discussion on what we hoped you learned from completing the
  assignment and some further challenges or relevant resources.

If you are already comfortable with the present topic or you'd like to explore 
it on your own before looking at the walkthrough/discussion, feel free to do so 
(although we recommend at least coming back here for the analysis section)! This
class is all about explorative learning and is much more open ended than CS241. 
While your MPs and Labs from CS241 will help you master the techniques and gain 
the knowledge required to call yourself a systems programmer, these MPs will be 
brainteasers or puzzles to further your interest in a particular area.

## Requirements:

Create an implementation of a dictionary by using clang's blocks!
Your implementation will have a single entry point that is a variadic function.
You will need to support the following operations:

+ lookup
+ insert
+ destroy

The runtime of your implementation does not matter (O(n) lookups are fine!)

To invoke a particular operation the user should pass in a string with the name
of that operation, followed by any arguments that operation may use. The
arguments consumed by each of the operations, and their behaviors are described
in the pseudo code example below:

```c
int main() {
  auto my_dict = create_dictionary();

  // This line makes _dictionary_destructor be called automatically when my_dict
  // goes out of scope 
  // _dictionary_destructor takes in a double pointer (because of clang's type
  // restrictions) but to access the underlying dictionary, just have the line:
  //     dictionary_t d = (dictionary_t)(*e);
  // in your _dictionary_destructor implementation
  auto_cleanup(my_dict);
  // The following line initializes a dict_value to hold a key of "k1", with a 
  // value of "v1". The length of the value is 3 (2 bytes for 'v' and '1' plus 
  // an extra byte for the null byte)
  dict_value new_val = { .key="k1", .value_len=3, .value="v1" };
  dict_value new_val1 = { .key="k2", .value_len=3, .value="v2" };

  my_dict("insert", &new_val, &new_val1, NULL);
  // The insert operation should keep consuming arguments of type dict_value* 
  // until it sees a NULL. The return value after an insert is undefined.
  // There should be no upper limit (aside from memory contraints) on how many
  // times insert can be called.

  dict_value = my_dict("lookup", "k1");
  // The lookup operation consumes one value which is the key it is looking for
  // inside it's dictionary. If the key is found, return the dict_value which
  // matched. Otherwise, return dict_NULL

  my_dict("destroy");
  // The same as calling my_dict(NULL); You will need to support both
  // The destroy operation consumes no arguments and should free any heap memory
  // used interally and reset the internal state for further use.
  // The return value is undefined.

}

```
You should also be able to use multiple instances of the dictionary at any given
time (it doesn't have to be thread safe, if you already know what that means).

The dictionary has a destructor method `_dictionary_destructor` which should
call the dictionary's destroy method and `Block_release` on the dictionary.
We've set this up to be the case automatically when `auto_cleanup` is called on
the created dictionary.

# Walkthrough

Ideally, this assignment shouldn't take more than 2 hours using the walkthrough.
If it does take you longer than that, we encourage you to reach out to course
staff and detail where you're stuck or what seems difficult about the
assignment! This will help us update our documentation and/or the course content
accordingly.

### (OPTIONAL) Exploring variadic functions

Variadic functions are a controversial part of the C language - and for good
reason! A variadic function is one that doesn't define how many parameters it
expects at compile time. There's some clear use cases for variadic functions,
such as `printf`. Have you ever wonder how to declare a function like `printf`
that can take in a variable number of arguments of any type? The answer is to
declare a variadic function. Of course, variadic functions have some nasty
downsides. One of them is that it simply leads to code that's harder to read
since it obtains its arguments in a strange way. Another major downside is that
you can't tell the compiler what types you want your arguments to have - leading
to more situations where a programmer can create insidious bugs.

_fun fact:_ Variadic functions are pretty common in languages, a notable
example being python. However, python has better semantics around this feature
by providing an array containing all passed in arguments as opposed to C's
approach described below.

So how can we declare a variadic function? In early versions of C, it was as
simple as just writing:

```c
f()
```

A far cry from what something we might see today:

```c
int f(int x, ...)
```

Let's try writing an actual variadic function. The function that we're going to
write is going to take in an integer `n` telling us how many arguments to expect
and then `n` integers which we will find the sum of. We'll start with the
prototype of the function:

```c
int sum(int n, ...)
```

This is the same as the example we have above. Note that it's not important for
our return type to be int, or the first parameter's type to be int. It is
required for there to be one or more named arguments before we have the `...`
that signifies that this is a variadic function. We need at least one named
parameter because we're going to use it to obtain the unnamed parameters. In C,
when passing in arguments, the arguments are placed onto the stack after the
return address. When we're looking for variadic arguments, all we have to do is
get the pointer to the last named argument, and continue reading the stack
memory after it. Of course, this requires us to make assumptions about the type
of data that was initially passed in. Luckily, by including the header `stdarg`
we get some macros that make it easier for us to extract these arguments.

The first thing we're going to need is a variable of type `va_list` that stores
the state required to figure out where the next argument will be located. We
will be initializing this list with the macro `va_start` which will setup our
list so that we can start pulling arguments out of it.

```c
#include <stdarg.h>
int sum(int n, ...){
    va_list args;
    va_start(args, n);
    return 0;
}
```

Note that `va_start` takes in the last named argument as one of its parameters.
Now we can start pulling values out of the stack. To do this we can use the
macro `va_arg`. `va_arg` takes in a `va_list` and a type so that it knows what
type the argument it pulls out should have. We can't normally pass a type name
as an argument to a function, but there's nothing stopping us from passing in a
type name as a parameter to a macro. Putting this information together, we get:

```c
#include <stdarg.h>
int sum(int n, ...){
    va_list args;
    va_start(args, n);
    int accumulator = 0;
    for (;n > 0; n--){
       accumulator += va_arg(args, int); 
    }
    return accumulator;
}
```

In this example we had the first argument to the function be the number of
arguments we're going to need. This isn't always the case. Some functions use
other mechanisms such as reading in elements until it reads NULL or some other
special value.

Try writing your own variadic functions in C! One interesting exercise could be
to write a simple parser for an arithmetic expression such as `$1 + $2` and
replace `$n` with the value of the nth variadic argument to make a simple
calculator.

Note that C also has variadic macros, which work a bit differently. Look online
to see how you can write a variadic macros which works out how many arguments
were passed in to it.

### (OPTIONAL) Exploring clang blocks

Clang blocks are a way to write functions within functions. It's a feature that
was initially developed by Apple for use in Objective-C, but eventually made
it's way back to C as a language extension. 

Blocks give us better ways to describe functions and enable us to pass them
around in ways that are increasingly common in languages such as Python,
JavaScript and almost all functional programming languages (e.g. Haskell, OCaml,
etc.).

So what is a Block? A Block is essentially a function pointer but also some
state that the function might reference. Let's take a look as some example
python code.

```python
def adder(x):
    def add_to_x(y):
        return x + y
    return add_to_x
```

This function takes in a number, and then returns a function which takes in
another number and spits out the sum of the two numbers. However, in order for
that inner function to work, it needs to remember what value was passed in for
`x` so that it can reuse it. In other words, it needs to remember what was
inside the scope of its parent function.

The corresponding implementation of the above function in C using Clang's Blocks
would be:

```c
#include <Block.h>
typedef int (^ AddIntBlock)(int)
AddIntBlock MakeAdder(int to_add) {
	return Block_copy( ^(int x) {
		return x + to_add;
  });
}
```

I'm using a `typedef` to make the code a bit more readable. You may note that
block types look similar to function pointers, except that the `*` is replaced
by a `^`. We're also using a function `Block_copy` which takes in a block and
copies the current scope into it. By default, Blocks assume that they don't need
to save the scope of the parent, and that they can just read the values present.
This works as long as those variables haven't gone out of scope, at which point,
executing the function will lead to undefined behavior. The actual code defining
the Block is just:

```c
int ^(int x) { return x + to_add; }
```

We can leave off the return type (int) and let clang figure that out for us, so
all we have to write is:

```c
^(int x) { return x + to_add; }
```

Pretty straightforward syntax if you ask me! Of course, since we called
`Block_copy` we've allocated some memory to hold stuff that the parent owned. We
will need to deallocate this using `Block_release`. A complete program may look
like:

```c
#include <Block.h>
#include <stdio.h>
typedef int (^ AddIntBlock)(int);
AddIntBlock MakeAdder(int to_add) {
	return Block_copy( ^(int x) {
		return x + to_add;
  });
}

int main(){
    AddIntBlock add_5 = MakeAdder(5);
    // Clang supports using __auto_type to do what auto does in C++
    //   It's very useful for representing Blocks since they have rather verbose
    //   type names
    __auto_type add_and_print = 
        ^(int n) { printf("%d + %d = %d\n", n, 5, add_5(n)); }; 
    add_and_print(1);
    add_and_print(5);
    Block_release(add_5);
    // Note that we don't need to release add_and_print since we didn't copy any
    // data into the block.
}
```

We can also have variadic blocks - which you will need to complete this
assignment.


### Hints

So what will our implementation of the dictionary actually look like? We know we
need some way to store the `data_value` elements that we will be getting from
insert. The easiest way to do this would be to declare some variable
representing an array of `data_values`. The challenge is that we need to store
this data somewhere that the function that represents the dictionary can access
every time it is called.

One way we could accomplish this is with a global variable. This could be an
interesting solution, but we would like to able to use multiple instances.
Although there are ways to make this work using globally scoped variables (Can
you think of any?) there are far better solutions out there. Globally scoped
variables can be hard to document and keep track of. It also exposes the
internals of your data structure to the world, and could lead to potentially
strange bugs causes by accidentally changing internal values. 

We need something that acts like a global variable, in that we have access to it
on every call of the function without needing the caller to pass it in, but we
want this variable to only be scoped to the dictionary. Thought of anything that
fits the bill here? (Take a moment to see if you can figure it out for
yourself!)

We can use the `__block` keyword! When using the clang blocks extension,
declaring a variable as `__block` will make the variable act like a `static`
variable but bound to a block. Using `static` in a block is undefined behavior.
So instead of using a global array of dict_values, we can use a static one. 

This brings us to our next point. We don't know how many elements we have
beforehand, when declaring an array we have to specify how many elements we
expect to have.  A better choice might be to just have a pointer instead of an
array, and then get space for it using calloc or malloc. We can still treat the
variable as an array, and easily add more space to the end using realloc! The
only thing we might need to keep track of is how many elements we have.

In order to make our implementation follow good coding practices, we should
probably put each operation in it's own block inside the dictionary
implementation (its like inception, but with functions). This will produce code
that looks vaguely similar to definitions of a class in C++ or other object
oriented languages.

Now, we just need a way to access the functions we've built in our dictionary.
To accomplish this we can just write a series of `if` statements and find out
what action the user wants to perform. Once we know what action the user is
requesting, we can assume that the remaining variadic arguments conform to the
specifications detailed above.

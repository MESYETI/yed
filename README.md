# yed
What if ed commands were stack based and also really ugly?

## Build
```
dub build
```

## Usage
Statements are separated with `#`. Write `#` at the start of your input to write a command,
otherwise it will be inserted into the current buffer.

A statement starting with `.` is a command. If it doesn't start with `.`, then it is
a string that gets pushed to the stack.

### Commands (with parameters)
#### `la ( -- )`
Prints every line in the current buffer

#### `n ( num -- )`
Sets the current line to `num`

#### `n? ( -- num )`
Pushes the current line to the stack

#### `l ( from to -- )`
Prints every line in the buffer from the lines `from` to `to`

#### `o ( path -- )`
Reads the lines from `path` into the current buffer. All old data in the buffer is
deleted.

#### `s ( -- )`
Writes the contents of the buffer to the current buffer's path

#### `sa ( path -- )`
Sets the current buffer's paths and writes the contents of the buffer to that path

#### `dup ( n -- n1 n2 )`
Duplicates the value on the top of the stack

#### `r ( from to -- )`
Replaces all instances of `from` to `to` in the current line

#### `end? ( -- end )`
Pushes the last line in the buffer to the stack

#### `p ( -- )`
Prints the current line

#### `b ( buf -- )`
Sets the current buffer to `buf`. If a buffer does not exist with that number, then
it will be created

#### `f ( str -- )`
Prints all lines in the current buffer containing `str`

#### `d (line -- )`
Deletes `line` in the buffer

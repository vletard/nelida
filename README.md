
NELIDA documentation
--------------------

The Never Ending Learning Dialogic Assistant is a simple dialog system that uses the principle of analogical reasoning to accept queries in natural language and produce commands in a programming language.

Author: Vincent Letard (letard.vincent@gmail.com)

## Usage

The execution of the script should be rather self explanatory.
Here are a few things to note before launching:
* nelida creates and uses the directory ~/.nelida/ for logging and example base saving (find and edit the `db_path` variable in the script if you want to manage several example bases)
* it is recommended to have rlwrap insalled: this allows path completion while typing queries as well as history navigation

Initializing `analogy/` submodule:
```
git submodule update --init
```

Launching nelida:
```
./nelida.sh
```

## Behaviour

### Learning

The software is learning incrementally and is provided with zero knowledge.
Along with the queries and the failed suggestions from the system, you will be asked to teach it the correct commands corresponding to your queries.
The more commands you use on an everyday basis, the more examples you might have to teach the system before it is able to provide satisfying suggestions.

### Note about the input and output domains

The dialog part of the system is currently written in French only, however there is no constraint on input or output languages.
Input language can be any natural language and the system can even be taught several inputs in different languages.
Output language can be anything as well, however please note that it has to be always the same in order for the system to provide consistent suggestions.

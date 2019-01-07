## Build Jolie Standard Library

`build_jsl` is a Jolie script that builds the Jolie standard library.

It depends from [liquidService](https://github.com/thesave/liquidService), which can be installed automatically by running the script `install_dependencies.ol`.

Usage example: 
```
jolie -l "liquid/lib:liquid/lib/*" build_jsl.ol ".md" "markdown_joliedoc.liquid"
```

Where the first argument passed to `build_jsl.ol` (in the example `.md`) is the document extension format outputted by the program and the second (in the example `markdown_joliedoc.liquid`) is a [liquid template](https://shopify.github.io/liquid/) used to automatically generate the documentation page.

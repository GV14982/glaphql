# glaphql

A Gleam GraphQL implementation for type-safe, performant GraphQL server and client development.

[![Package Version](https://img.shields.io/hexpm/v/glaphql)](https://hex.pm/packages/glaphql)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glaphql/)

## Installation

```sh
gleam add glaphql
```

## Quick Start

```gleam
import glaphql

pub fn main() {
  // This is a placeholder for a basic GraphQL server/client example.
  // See the test suite for real usage patterns, including schema parsing,
  // validation, and operation execution.
}
```

## Project Structure

```
glaphql/
├── src/
│   └── internal/
│       ├── executable/       # Executable schema and operation construction
│       ├── lexer/            # Lexer/tokenizer for GraphQL source
│       ├── parser/           # Parser for GraphQL schema and operations
│       ├── validate/         # Validation logic for schemas and queries
│       └── util.gleam        # Internal utilities
│   └── errors.gleam          # Custom error types for all modules
├── test/                     # Project test suite (see for usage examples)
├── gleam.toml                # Project configuration
└── README.md                 # Project documentation
```

## Features

### Implemented
- [x] Lexer and parser for GraphQL SDL and operations
- [x] Schema and operation validations

### Planned
- [ ] Resolver codegen
- [ ] Client codegen
- [ ] Performance optimizations
- [ ] Enhanced type safety and documentation

## Development

```sh
gleam run     # Run the project (if main entry point exists)
gleam test    # Run the tests (recommended: see test/ for usage)
gleam shell   # Run an Erlang shell
gleam build   # Build the project
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Doc Comments Policy

All public functions and types **must** have doc comments describing their purpose, arguments, and return values where appropriate. This ensures high-quality documentation and helps users and contributors understand the codebase.

- If you add or modify a public API, include or update doc comments.
- Internal/private helpers do not require doc comments unless they are complex or non-obvious.

## License

This project is licensed under the MIT License.

```
MIT License

Copyright (c) 2024 Graham Vasquez

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Further Documentation

- More detailed documentation can be found at <https://hexdocs.pm/glaphql>.
- See the `test/` directory for practical usage and integration examples.

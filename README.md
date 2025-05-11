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
  // TODO: Provide a basic GraphQL server/client example
}
```

## Project Structure

```
glaphql/
├── src/
│   ├── internal/
│   │   ├── schema/           # Core GraphQL schema types and definitions
│   │   ├── validate/         # Validation logic for GraphQL schemas and queries
│   │   └── errors.gleam      # Custom error handling
│   └── glaphql.gleam         # Main library entry point
├── test/                     # Project test suite
└── gleam.toml                # Project configuration
```

## Features Roadmap

### Implemented
- [x] Basic GraphQL schema definition
- [x] Type validation
- [x] Error handling

### Planned Features
- [ ] Full GraphQL specification support
- [ ] Server-side query execution
- [ ] Client-side query generation
- [ ] Subscription support
- [ ] Performance optimizations
- [ ] Comprehensive type safety

## Development

```sh
gleam run     # Run the project
gleam test    # Run the tests
gleam shell   # Run an Erlang shell
gleam build   # Build the project
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

[TODO: Add license information]

## Further Documentation

More detailed documentation can be found at <https://hexdocs.pm/glaphql>.

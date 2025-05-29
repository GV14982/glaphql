# Contributing to glaphql

Thank you for your interest in contributing to **glaphql**! Your help is greatly appreciated. This document outlines the process and guidelines for contributing to the project.

---

## How to Contribute

1. **Fork the repository**  
   Click the "Fork" button at the top right of the repository page.

2. **Clone your fork**  
   ```
   git clone https://github.com/your-username/glaphql.git
   cd glaphql
   ```

3. **Create a feature branch**  
   ```
   git checkout -b feature/your-feature-name
   ```

4. **Make your changes**  
   - Follow the code style and documentation guidelines below.
   - Add or update tests as appropriate.

5. **Commit your changes**  
   ```
   git commit -m "Describe your changes"
   ```

6. **Push to your fork**  
   ```
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**  
   - Go to the original repository and click "Compare & pull request".
   - Fill in the PR template and describe your changes.

---

## Code Style

- **Language:** This project is written in [Gleam](https://gleam.run/).
- **Formatting:** Run `gleam format` before submitting your PR.
- **Naming:** Use descriptive, consistent names for functions, types, and variables.
- **Tests:** All new features and bug fixes should include appropriate tests in the `test/` directory.
- **Commits:** Write clear, concise commit messages.

---

## Doc Comments Policy

All public functions and types **must** have doc comments. This ensures high-quality documentation and helps users and contributors understand the codebase.

- **What to document:**  
  - All `pub fn`, `pub type`, and `pub const` definitions.
  - Describe the purpose, arguments, and return values.
- **How:**  
  - Use triple-slash `///` comments above the item.
  - Example:
    ```
    /// Returns the sum of two integers.
    ///
    /// ## Arguments
    /// - `a`: The first integer
    /// - `b`: The second integer
    ///
    /// ## Returns
    /// - The sum of `a` and `b`
    pub fn add(a: Int, b: Int) -> Int {
      a + b
    }
    ```
- **Private/internal helpers:**  
  - Doc comments are optional unless the function is complex or non-obvious.

---

## Reporting Issues

If you find a bug or have a feature request, please [open an issue](https://github.com/grahamvasquez/glaphql/issues) and provide as much detail as possible.

---

## Code of Conduct

Be respectful and inclusive. Harassment or abusive behavior will not be tolerated.

---

Thank you for helping make **glaphql** better!
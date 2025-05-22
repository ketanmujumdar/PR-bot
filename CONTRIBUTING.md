# Contributing to PR-bot

Thank you for your interest in contributing to PR-bot! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Contribution Workflow](#contribution-workflow)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Issue Reporting](#issue-reporting)
- [Feature Requests](#feature-requests)
- [Community](#community)

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please be respectful and considerate when interacting with other community members.

## Getting Started

1. **Fork the repository**: Start by forking the PR-bot repository on GitHub.

2. **Clone your fork**: 
   ```bash
   git clone https://github.com/YOUR-USERNAME/PR-bot.git
   cd PR-bot
   ```

3. **Add the upstream remote**:
   ```bash
   git remote add upstream https://github.com/ORIGINAL-OWNER/PR-bot.git
   ```

4. **Install dependencies**:
   ```bash
   # Make sure the script is executable
   chmod +x install.sh
   
   # Run the installation script
   ./install.sh
   ```

## Development Environment

PR-bot is primarily a bash script-based tool. To contribute effectively:

- Use a UNIX-like operating system (macOS, Linux)
- Have a working installation of bash
- Ensure you have git installed
- Install jq for JSON processing
- For testing PR creation features, install GitHub CLI
- Install whiptail (or newt) for GUI-based selection

## Contribution Workflow

1. **Create a new branch**:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. **Make your changes**: Implement your feature or fix.

3. **Test your changes**: Ensure your changes work as expected.

4. **Commit your changes**:
   ```bash
   git commit -m "feat: description of your feature"
   # or
   git commit -m "fix: description of your fix"
   ```
   
   We follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages.

5. **Stay up to date with upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

6. **Push your changes**:
   ```bash
   git push origin your-branch-name
   ```

7. **Create a pull request**: Open a pull request from your forked repository to the original repository.

## Pull Request Guidelines

- PR titles should follow the [Conventional Commits](https://www.conventionalcommits.org/) format
- Include a detailed description of the changes
- Link related issues using keywords like "Closes #123" or "Fixes #123"
- Include screenshots for UI changes (if applicable)
- Ensure all tests pass
- Keep PRs focused on a single change or feature

## Coding Standards

For bash scripts:
- Use shellcheck to validate your scripts
- Add comments to explain complex logic
- Use meaningful variable and function names
- Follow the existing code style:
  - 2-space indentation
  - Clear error handling
  - Descriptive function names
- Use functions to encapsulate reusable code
- Use appropriate environment variables for configuration

## Testing

Before submitting a PR, test your changes:

1. Test on both macOS and Linux if possible
2. Test with different LLM providers (Gemini, OpenAI, local LLMs)
3. Test both installation methods (system-wide and user-only)
4. For UI changes, test both whiptail and text-based interfaces
5. Test with various repository sizes and commit histories

## Documentation

When adding new features or changing existing ones, update the relevant documentation:

- Update README.md for user-facing changes
- Add comments to explain complex code
- Update help text and usage instructions
- Update template files if applicable

## Issue Reporting

When reporting issues, please include:

- A clear, descriptive title
- A detailed description of the issue
- Steps to reproduce the problem
- Expected behavior
- Actual behavior
- Your environment (OS, bash version, etc.)
- Screenshots if applicable

## Feature Requests

Feature requests are welcome! Please provide:

- A clear, descriptive title
- A detailed description of the proposed feature
- Any relevant examples or use cases
- If possible, information about how you might implement it

## Community

- Respect all community members
- Provide constructive feedback
- Help others when you can
- Share your knowledge and experiences

Thank you for contributing to PR-bot!

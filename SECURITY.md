# Security Policy

## Supported Versions

The following versions of PR-bot are currently being supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of the PR-bot tool seriously. If you believe you've found a security vulnerability, please follow these steps:

### How to Report

1. **Do Not** disclose the vulnerability publicly until it has been addressed.
2. Email the details to [security@example.com](mailto:security@example.com) or create a private security advisory on GitHub.
3. Include as much information as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fixes (if any)

### What to Expect

After submitting a vulnerability report:

1. You'll receive an acknowledgment within 48 hours.
2. We'll investigate and determine the vulnerability's scope and severity.
3. We'll work on a fix and release plan.
4. We'll keep you informed about our progress.

### Disclosure Policy

- We follow a coordinated disclosure process.
- Once a fix is ready, we'll release a patch and acknowledge your contribution (if desired).
- Public disclosure will occur after users have had sufficient time to update.

## Security Best Practices for Users

When using PR-bot, consider these security recommendations:

1. **API Keys**: Store your API keys securely. Never commit them to your repository.
2. **Keep Updated**: Always use the latest version of PR-bot to benefit from security patches.
3. **Local LLMs**: Consider using local LLMs when processing sensitive code to avoid transmitting proprietary code to external APIs.
4. **Permissions**: When using the GitHub CLI integration, be mindful of the permissions granted.

## Security Features

PR-bot includes several security-conscious features:

- Secure storage of API keys in a protected configuration file
- Support for local LLMs to avoid sending sensitive code to third-party services
- Clear separation between your code and the generated PR descriptions

## Dependencies

This tool depends on several external components. We recommend:

- Keeping your operating system updated
- Using the latest version of Git
- Keeping GitHub CLI updated if you use the PR creation feature

## Code of Conduct

We expect all contributors to adhere to ethical security practices, including responsible disclosure of vulnerabilities.
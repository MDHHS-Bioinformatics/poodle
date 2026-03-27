# Contributing to PoODLE

Thank you for your interest in contributing to this project.

This pipeline is maintained by the Genomics Analysis Unit at the Michigan Department of Health & Human Services (MDHHS) Bureau of Laboratories. We welcome contributions that improve reproducibility, clarity, performance, and public health utility.

---

## 🧭 Ways to Contribute

You can contribute by:

- 🐛 Reporting bugs
- 💡 Suggesting new features
- 📚 Improving documentation
- 🧪 Adding tests
- ⚡ Improving performance
- 🧬 Enhancing reproducibility
- 🔧 Submitting pull requests

---

## 🐛 Reporting Issues

Before opening a new issue:

1. Search existing issues.
2. Confirm you are using the latest release.

When submitting a bug report, please include:

- Pipeline version (`nextflow run ... -r vX.Y.Z`)
- Nextflow version (`nextflow -version`)
- Execution profile used
- Full command executed
- Relevant log files (`.nextflow.log`)
- Minimal reproducible input (if possible)

The more reproducible the issue, the faster we can resolve it.

---

## 💡 Feature Requests

Feature requests are welcome.

Please include:

- Public health use case
- Rationale
- Expected benefit
- Whether change is backward compatible

Major feature changes should be discussed in an issue before submitting a pull request.

---

## 🔀 Pull Request Workflow

1. Fork the repository.
2. Create a new branch from `main`:

   ```bash
   git checkout -b feature/my-feature
   ```

3. Make focused, atomic commits.
4. Ensure the pipeline runs successfully.
5. Run the test profile (if available).
6. Submit a pull request to `dev` branch.

---

## ✅ Pull Request Requirements

All pull requests should:

* Preserve reproducibility
* Maintain backward compatibility (unless discussed)
* Include updated documentation if needed
* Update parameter descriptions if changed
* Follow code style conventions

For major changes:

* Add or update tests
* Update `CHANGELOG.md`
* Bump version if appropriate

---

## 🧪 Testing Expectations

Contributors should:

* Test with the provided `-profile test`
* Confirm no unexpected output structure changes
* Ensure containers build and run correctly
* Confirm `-resume` works when applicable

If introducing new parameters:

* Provide defaults
* Update README and docs
* Ensure sensible failure messages

---

## 🧬 Code Style Guidelines

### Nextflow

* Use DSL2 syntax
* Keep modules modular and reusable
* Avoid hard-coded paths
* Use parameter validation where appropriate
* Document non-obvious logic with comments

### Containers

* Pin software versions
* Avoid `latest` tags
* Ensure deterministic builds

### Configuration

* Separate profiles cleanly
* Avoid environment-specific assumptions
* Keep resource limits configurable

---

## 🔒 Security & Sensitive Data

This repository is intended for use with non-sensitive and publicly available data only.

Do not:

* Include PHI or PII
* Upload real surveillance datasets
* Commit confidential information

If you discover a security issue, please contact the maintainers directly instead of opening a public issue.

---

## 📦 Reproducibility Standards

All contributions must preserve:

* Containerized execution
* Versioned releases
* Deterministic outputs (given identical inputs)
* Proper logging

Reproducibility is critical in public health investigations.

---

## 🏛 Governance

The maintainers reserve the right to:

* Decline features that fall outside intended scope
* Prioritize public health needs
* Request modifications before merging

Major architectural decisions may require internal review.

---

## 📝 Commit Message Guidelines

We recommend:

* Use clear, concise messages
* Reference issue numbers when applicable
* Example:

  ```
  fix: correct SNP distance threshold handling (#42)
  feat: add optional recombination masking parameter
  docs: clarify manifest requirements
  ```

Optional convention:

* `feat:` new feature
* `fix:` bug fix
* `docs:` documentation
* `refactor:` internal restructuring
* `test:` test updates

---

## 🤝 Code of Conduct

All contributors are expected to act professionally and respectfully.

See [`Code of Conduct`](CODE_OF_CONDUCT.md).

---

## 📜 License

By contributing, you agree that your contributions will be licensed under the same license as this project. This project is released under the [**MIT License**](LICENSE).



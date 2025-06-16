# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 7.2.x   | :white_check_mark: |
| 7.0.x   | :white_check_mark: |
| < 7.0   | :x:                |

## Security Features

### Container Security
- **Non-root execution**: Container runs as UID 1997 (non-privileged user)
- **Minimal attack surface**: Only essential packages are installed
- **Vulnerability scanning**: Automated security scanning with Trivy
- **Supply chain security**: SBOM generation and provenance attestation

### Script Security
- **Input validation**: All scripts validate input parameters
- **Command injection prevention**: Dangerous commands are blocked
- **Audit logging**: Command executions are logged for security monitoring
- **Timeout controls**: Scripts have timeout limits to prevent resource exhaustion

### Network Security
- **Principle of least privilege**: Scripts only allow necessary network operations
- **Port validation**: Network utilities validate port ranges
- **Connection timeouts**: All network operations have strict timeouts

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **DO NOT** create a public GitHub issue
2. Email security details to: [your-security-email@example.com]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline
- **Initial response**: Within 48 hours
- **Investigation**: Within 1 week
- **Fix deployment**: Within 2 weeks for critical issues

### Security Best Practices

When using this container:

1. **Environment Variables**: Never pass sensitive data through environment variables in production
2. **Network Access**: Restrict network access using Docker networks or firewall rules
3. **File Permissions**: Mount volumes with appropriate permissions
4. **Updates**: Regularly update to the latest version
5. **Monitoring**: Monitor container logs for suspicious activity

### Known Security Considerations

1. **Remote Commands**: If `ZBX_ENABLEREMOTECOMMANDS=1` is set, additional security measures should be implemented
2. **SNMP Community Strings**: Use strong, unique community strings for SNMP monitoring
3. **Database Access**: Secure the SQLite database file with appropriate file permissions

## Security Contact

For security-related questions or concerns:
- Email: [your-security-email@example.com]
- PGP Key: [Link to your PGP public key]

## Acknowledgments

We appreciate responsible disclosure of security vulnerabilities and will acknowledge reporters (with their permission) in our security advisories.

# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 7.2.x   | :white_check_mark: |
| 7.0.x   | :white_check_mark: |
| < 7.0   | :x:                |

**Note**: Security support is provided on a best effort basis for this community project.

## Security Features

### Container Security
- **Non-root execution**: Container runs as UID 1997 (non-privileged user)
- **Minimal attack surface**: Only essential packages are installed
- **Vulnerability scanning**: Automated security scanning with Trivy (non-blocking for awareness)
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

### Critical Security Issues

For **critical security vulnerabilities** that affect Zabbix core functionality:

1. **Report directly to Zabbix**: Follow [Zabbix's official security reporting process](https://www.zabbix.com/security)
2. These issues should be handled by the upstream Zabbix security team

### Implementation-Specific Issues

For security issues **specific to this SQLite3 proxy implementation**:

1. Create a **pull request** with:
   - Description of the security concern
   - Proposed fix or mitigation
   - Test cases (if applicable)

2. For sensitive issues that shouldn't be public initially:
   - Create a draft pull request
   - Contact maintainers through GitHub to discuss privately first

### Response Timeline

**Best effort basis**:
- **Initial response**: Within 1 week
- **Investigation and fixes**: Timeline depends on maintainer availability
- **Critical upstream issues**: Refer to Zabbix's security timeline

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

## Acknowledgments

We appreciate responsible disclosure of security vulnerabilities and will acknowledge contributors in our release notes. For critical Zabbix core issues, please follow Zabbix's official acknowledgment process.

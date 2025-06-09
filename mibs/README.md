# Custom SNMP MIBs Directory

This directory can be used to add custom SNMP MIBs to the Zabbix Proxy container.

## Usage

Place your custom MIB files in this directory. They will be copied to `/usr/share/snmp/mibs/custom` inside the container during build.

## Requirements

- MIB files should be in standard SNMP MIB format
- File names should typically end with `.txt` or have no extension
- Avoid having spaces or special characters in the file names

## Benefits

- Custom MIBs will be available to all SNMP tools in the container
- No need to modify the container after deployment
- Clean separation between standard and custom MIBs

## Example

If you have a custom MIB file called `MY-CUSTOM-MIB.txt`, place it in this directory and it will be available in the container at `/usr/share/snmp/mibs/custom/MY-CUSTOM-MIB.txt`.

## Testing

You can test that your custom MIB is being properly loaded using:

```bash
snmptranslate -IR -Td MY-CUSTOM-MIB::objectName
```

## Troubleshooting

If your MIB isn't being recognized, check:

1. The MIB format is valid (syntax errors will prevent loading)
2. Any dependent MIBs are also present
3. File permissions are correct (should be readable)
4. The container has been rebuilt after adding the MIB files

# Foam Vault Template

This repository is a clean **Foam-first Markdown vault template**.

## Initialize the vault

### PowerShell
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\init-foam.ps1
```

### Shell
```bash
bash ./scripts/init-foam.sh
```

The init script removes old vault data and rebuilds a clean atomic-note workspace.
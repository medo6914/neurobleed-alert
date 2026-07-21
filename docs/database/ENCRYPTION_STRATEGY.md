# Encryption Strategy

## Column-Level Encryption

### Sensitive Fields Encrypted at the Column Level

| Model | Field | Encryption Method |
|-------|-------|-------------------|
| User | `mfa_secret` | AES-256-GCM with application key |
| User | `hashed_password` | bcrypt (passlib) |
| User | `phone` | AES-256-GCM (if PII flag set) |
| Patient | `national_id` | AES-256-GCM |
| Patient | `phone` | AES-256-GCM |
| Patient | `email` | AES-256-GCM |
| Patient | `emergency_contact_phone` | AES-256-GCM |
| Device | `sim_iccid` | AES-256-GCM |

### Implementation with SQLAlchemy

```python
from cryptography.fernet import Fernet

cipher = Fernet(settings.ENCRYPTION_KEY.encode())

class EncryptedString(TypeDecorator):
    impl = String

    def process_bind_param(self, value, dialect):
        if value is not None:
            return cipher.encrypt(value.encode()).decode()
        return None

    def process_result_value(self, value, dialect):
        if value is not None:
            return cipher.decrypt(value.encode()).decode()
        return None
```

### Usage

```python
class Patient(Base):
    __tablename__ = "patients"
    national_id = mapped_column(EncryptedString(100), nullable=True)
```

## Encryption at Rest

### PostgreSQL pgcrypto Extension

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

Use pgcrypto for server-side encryption functions:

```sql
-- Encrypt with pgp_sym_encrypt
INSERT INTO patient_ssn (patient_id, encrypted_ssn)
VALUES ($1, pgp_sym_encrypt($2, current_setting('app.encryption_key')));

-- Decrypt
SELECT pgp_sym_decrypt(encrypted_ssn, current_setting('app.encryption_key'))
FROM patient_ssn WHERE patient_id = $1;
```

### Transparent Data Encryption (TDE)

For production PostgreSQL (AWS RDS / Azure Database):

- **AWS RDS**: Enable RDS encryption at rest (AES-256) using AWS KMS.
- **Azure**: Enable Transparent Data Encryption with Azure Key Vault.
- **Self-hosted**: Use LUKS/dm-crypt or PostgreSQL pg_tde extension.

TDE encrypts the entire database files at the storage layer, protecting against:
- Physical disk theft
- Unauthorized file system access
- Backup tape breaches

## Encryption in Transit

### TLS 1.3 Configuration

```python
import ssl

SSL_CONTEXT = ssl.create_default_context(ssl.Purpose.SERVER_AUTH)
SSL_CONTEXT.minimum_version = ssl.TLSVersion.TLSv1_3
SSL_CONTEXT.set_ciphers("ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM")
```

### PostgreSQL TLS Settings

```ini
# postgresql.conf
ssl = on
ssl_min_protocol_version = 'TLSv1.3'
ssl_ciphers = 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384'
ssl_cert_file = '/etc/ssl/certs/server.crt'
ssl_key_file = '/etc/ssl/private/server.key'
```

### Connection String

```
postgresql+asyncpg://neurobleed:password@host:5432/neurobleed?ssl=require
```

## Key Management

### AWS KMS

```python
import boto3
from botocore.config import Config

kms = boto3.client(
    "kms",
    region_name="us-east-1",
    config=Config(retries={"max_attempts": 5}),
)

def decrypt_key(ciphertext_blob):
    response = kms.decrypt(CiphertextBlob=ciphertext_blob)
    return response["Plaintext"]
```

### Azure Key Vault

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://neurobleed-vault.vault.azure.net", credential=credential)
encryption_key = client.get_secret("data-encryption-key").value
```

### Key Hierarchy

```
Master Key (KMS / Key Vault)
    └── Data Encryption Key (DEK) — cached in application memory
        ├── Column encryption keys (per-field)
        ├── TLS private key
        └── PgBouncer auth file keys
```

## Key Rotation Procedure

### Regular Rotation Schedule

| Key Type | Rotation Frequency | Method |
|----------|-------------------|--------|
| Master Key (KMS) | Every 12 months | AWS automatic key rotation |
| Data Encryption Key | Every 6 months | Re-encrypt column values |
| TLS Certificate | Every 12 months | Let's Encrypt / ACM |
| PgBouncer auth | Every 3 months | Regenerate userlist.txt |

### DEK Rotation Script

```python
async def rotate_encryption_key(old_key: bytes, new_key: bytes):
    old_cipher = Fernet(old_key)
    new_cipher = Fernet(new_key)

    patients = await patient_repo.get_multi(limit=10000)
    for patient in patients:
        if patient.national_id:
            decrypted = old_cipher.decrypt(patient.national_id.encode())
            patient.national_id = new_cipher.encrypt(decrypted).decode()
    await db.commit()
```

## PII/PHI Identification and Protection

### Identified PII/PHI Fields

| Category | Fields | Protection |
|----------|--------|------------|
| Direct Identifiers | `national_id`, `email`, `phone` | Encrypted at column level |
| Quasi-Identifiers | `date_of_birth`, `gender`, `zip_code` | Restricted access + audit |
| Clinical Data | `icd10_code`, `medical_conditions` | Audit logging + access control |
| Biometric | `mfa_secret` | Encrypted + rate-limited |
| Device Identifiers | `sim_iccid`, `mac_address` | Encrypted + restricted |

### Access Control

- Role-based access: Only clinicians can read PHI.
- Audit logging: Every PHI access is logged to `audit_logs`.
- Masking: Non-clinician roles see masked PII (`123-****-6789`).

### Data Retention

- PHI retained per HIPAA requirements (6 years minimum).
- Anonymize patient records after retention period.
- Use `deleted_by_id` + `deleted_at` for audit trail on soft-delete.

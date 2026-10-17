# Security Baseline

- Store tokens only in platform secure storage.
- Never commit API keys, signing credentials, or device tokens.
- Treat OCR files, location, and push tokens as sensitive data.
- Inquiry attachments are picked through the system photo and document pickers, which need no storage permission. JPEG EXIF/XMP/IPTC segments and PNG `eXIf`/text chunks are removed on the device before upload; an image whose structure cannot be parsed is not uploaded.
- Send authenticated requests through one API boundary that handles expiry consistently.
- Do not trust student IDs from navigation arguments when the server can derive identity from the session.

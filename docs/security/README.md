# Security Baseline

- Store tokens only in platform secure storage.
- Never commit API keys, signing credentials, or device tokens.
- Treat OCR files, location, and push tokens as sensitive data.
- Inquiry attachments are picked through the system photo and document pickers, which need no storage permission. JPEG EXIF/XMP/IPTC segments and PNG `eXIf`/text chunks are removed on the device before upload; an image whose structure cannot be parsed is not uploaded.
- Send authenticated requests through one API boundary that handles expiry consistently.
- Do not trust student IDs from navigation arguments when the server can derive identity from the session.

- 성적표 PDF OCR은 서버로 파일이나 텍스트를 전송하지 않습니다. 변환용 임시 파일은 앱 전용 임시 디렉터리에서 처리 후 삭제합니다. 앱 또는 OS가 비정상 종료될 경우 임시 파일이 남을 수 있으므로 기기 캐시 정책도 고려합니다.

# Review-Prompt Template

Reviewe den folgenden Code auf:

1. **Korrektheit**: Logikfehler, Edge Cases
2. **Security**: Injection, XSS, hardcodierte Secrets
3. **Performance**: Unnoetige Iterationen, Memory-Leaks
4. **Best Practices**: Naming, Struktur, Error Handling

## Code
{{code}}

## Output-Format
- CRITICAL: [Beschreibung + Fix]
- HIGH: [Beschreibung + Fix]
- MEDIUM: [Beschreibung]
- OK: [Was gut ist]

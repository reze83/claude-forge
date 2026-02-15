# TypeScript / Node.js Projekt-Template

## Dateien erstellen

### package.json
```json
{
  "name": "<projektname>",
  "version": "0.0.1",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "lint": "eslint src/",
    "format": "prettier --write \"src/**/*.ts\""
  },
  "devDependencies": {
    "typescript": "^5.7",
    "tsx": "^4.19",
    "vitest": "^3.0",
    "@types/node": "^22",
    "eslint": "^9",
    "prettier": "^3"
  }
}
```

### tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2024",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "skipLibCheck": true,
    "declaration": true,
    "sourceMap": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

### Verzeichnisstruktur
```
src/
├── index.ts          # Einstiegspunkt
└── lib/              # Bibliotheks-Code
tests/
└── index.test.ts     # Tests
```

### .gitignore
```
node_modules/
dist/
*.log
.env*
CLAUDE.local.md
.claude/settings.local.json
```

### Nach Erstellung
```bash
npm install
```

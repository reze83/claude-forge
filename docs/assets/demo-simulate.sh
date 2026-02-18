#!/usr/bin/env bash
# Simulates a real Claude Code CLI conversation
# Matches the actual Claude Code UI: ❯ for user, ● for Claude, task indicators

G='\033[32m'          # Green
BG='\033[1;32m'       # Bold Green
HG='\033[92m'         # Bright Green
DG='\033[2;32m'       # Dim Green
W='\033[1;97m'        # Bold White
DW='\033[2;37m'       # Dim White/Gray
R='\033[91m'          # Bright Red (mascot)
DR='\033[31m'         # Dark Red (mascot shadow)
BK='\033[30m'         # Black (eyes)
NC='\033[0m'

clear

# Title
echo ""
echo -e "  ${BG}━━━ Multi-Model Workflow ━━━${NC}"
echo ""

# Claude Code header with mascot (exact chars from real CLI)
echo ""
echo -e "            ${BG}Claude Code${NC} ${DG}v2.1.32${NC}"
echo -e "  ${R}▐▛███▜▌${NC}   ${DG}Opus 4.6 · Claude Max${NC}"
echo -e " ${R}▝▜█████▛▘${NC}  ${DG}/home/c/my-api${NC}"
echo -e "   ${R}▘▘${NC} ${R}▝▝${NC}    ${HG}Opus 4.6 is here${NC}"
echo ""
sleep 1

# User prompt
echo -e "${HG}❯${NC} ${W}/multi-workflow Create a REST API with auth middleware${NC}"
echo ""
sleep 1.2

# Claude response — Phase 1
echo -e "${BG}●${NC} ${G}Analyzing task and reading project files...${NC}"
sleep 0.6
echo -e "  ${G}Reading package.json, tsconfig.json...${NC}"
sleep 0.5
echo -e "  ${G}Stack detected: ${HG}Node.js + TypeScript + Express${NC}"
sleep 0.4
echo -e "  ${G}Backend tasks identified — delegating to Codex${NC}"
echo ""
sleep 1

# Claude response — Phase 2
echo -e "${BG}●${NC} ${G}Planning implementation...${NC}"
sleep 0.5
echo -e "  ${G}Claude ${DG}→${NC} ${G}Auth middleware, route setup, integration${NC}"
sleep 0.3
echo -e "  ${G}Codex  ${DG}→${NC} ${G}JWT validation, user model, DB schema${NC}"
echo ""
sleep 1

# Task indicator — Codex delegation (matches real Claude Code task output)
echo -e "${BG}●${NC} ${G}Delegating backend tasks to Codex...${NC}"
echo ""
sleep 0.4
echo -e "  ${HG}Bash${NC}${DG}: codex-wrapper.sh --sandbox write --prompt \"Implement JWT auth\"${NC}"
sleep 2
echo -e "  ${DG}L${NC}  ${G}Done ${DG}(1 tool use · 2.1k tokens · 45s)${NC}"
echo ""
sleep 0.5
echo -e "  ${G}status: ${HG}success${NC} ${DG}|${NC} ${G}model: ${HG}codex${NC}"
echo -e "  ${G}Created: ${HG}src/auth/jwt.ts${NC}${G}, ${HG}src/models/user.ts${NC}${G}, ${HG}src/middleware/auth.ts${NC}"
echo ""
sleep 1.2

# Claude response — Implementation
echo -e "${BG}●${NC} ${G}Implementing Claude tasks and integrating Codex output...${NC}"
echo ""
sleep 0.5
echo -e "  ${HG}Write${NC}${DG}: src/routes/auth.ts${NC}"
sleep 0.4
echo -e "  ${HG}Edit${NC}${DG}: src/app.ts${NC}"
sleep 0.4
echo -e "  ${HG}Edit${NC}${DG}: src/auth/jwt.ts (refactored to match code standards)${NC}"
sleep 0.4
echo -e "  ${HG}Edit${NC}${DG}: src/middleware/auth.ts (refactored)${NC}"
sleep 0.3
echo -e "  ${DG}L${NC}  ${G}Done ${DG}(4 tool uses · 8.3k tokens · 1m 22s)${NC}"
echo ""
sleep 1

# Claude response — Review
echo -e "${BG}●${NC} ${G}Review complete.${NC}"
echo ""
sleep 0.4
echo -e "  ${G}Tests:     ${HG}4 passed${NC}${G}, 0 failed${NC}"
sleep 0.3
echo -e "  ${G}Security:  ${HG}No issues${NC}"
sleep 0.3
echo -e "  ${G}Standards: ${HG}TypeScript strict${NC}"
echo ""
sleep 0.6
echo -e "${BG}●${NC} ${G}Workflow complete — ${HG}3${NC} ${G}files by Codex, ${HG}2${NC} ${G}by Claude.${NC}"
echo ""
sleep 3

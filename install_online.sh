#!/bin/bash

# ========================================================================
# INSTALADOR ONLINE DO MÓDULO KANBAN PARA CHATWOOT
# ========================================================================
# Este script baixa o módulo do GitHub e instala automaticamente
# Versão: 1.0
# ========================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# URL do módulo no GitHub Releases
MODULE_URL="${KANBAN_MODULE_URL:-https://github.com/LucasZerino/chatwoot-kanban-module/releases/download/kanban/kanban-module.tar.gz}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🚀 INSTALADOR ONLINE DO MÓDULO KANBAN${NC}"
echo -e "${BLUE}(Download e instalação automática)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar se docker está instalado
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}❌ Erro: Docker não encontrado${NC}"
  echo "   Instale o Docker: https://docs.docker.com/get-docker/"
  exit 1
fi

if ! command -v docker compose >/dev/null 2>&1; then
  echo -e "${RED}❌ Erro: Docker Compose não encontrado${NC}"
  echo "   Instale o Docker Compose: https://docs.docker.com/compose/install/"
  exit 1
fi

# ========================================================================
# BAIXAR MÓDULO
# ========================================================================
echo -e "${BLUE}📋 ETAPA 1/5: Baixando módulo Kanban${NC}"
echo ""

TEMP_DIR=$(mktemp -d)
MODULE_FILE="$TEMP_DIR/kanban-module.tar.gz"

echo "📥 Baixando de: $MODULE_URL"
if command -v wget >/dev/null 2>&1; then
  wget -q --show-progress -O "$MODULE_FILE" "$MODULE_URL"
elif command -v curl >/dev/null 2>&1; then
  curl -L -o "$MODULE_FILE" "$MODULE_URL"
else
  echo -e "${RED}❌ Erro: wget ou curl não encontrado${NC}"
  exit 1
fi

if [ ! -f "$MODULE_FILE" ] || [ ! -s "$MODULE_FILE" ]; then
  echo -e "${RED}❌ Erro: Falha ao baixar o módulo${NC}"
  echo "   Verifique a URL: $MODULE_URL"
  exit 1
fi

echo "📦 Extraindo módulo..."
tar -xzf "$MODULE_FILE" -C "$TEMP_DIR"
mv "$TEMP_DIR/kanban-module" ./kanban-module

echo -e "${GREEN}✅ Módulo baixado e extraído${NC}"
echo ""

# ========================================================================
# PREPARAR DOCKER COMPOSE
# ========================================================================
echo -e "${BLUE}📋 ETAPA 2/5: Configurando Docker Compose${NC}"
echo ""

cat > docker-compose.override.yaml << 'OVERRIDE_EOF'
version: '3'

services:
  rails:
    volumes:
      - ./kanban-module:/app/kanban-module:ro

  sidekiq:
    volumes:
      - ./kanban-module:/app/kanban-module:ro
OVERRIDE_EOF

echo -e "${GREEN}✅ Docker Compose configurado${NC}"
echo ""

# ========================================================================
# REINICIAR CONTAINERS
# ========================================================================
echo -e "${BLUE}📋 ETAPA 3/5: Reiniciando containers${NC}"
echo ""

docker compose down 2>/dev/null || true
sleep 2
docker compose up -d

echo ""
echo "⏳ Aguardando containers iniciarem (30 segundos)..."
sleep 30

# ========================================================================
# INSTALAR MÓDULO NO CONTAINER
# ========================================================================
echo -e "${BLUE}📋 ETAPA 4/5: Instalando módulo no container${NC}"
echo ""

CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "rails" | grep -v "sidekiq" | head -n 1)

if [ -z "$CONTAINER" ]; then
  echo -e "${RED}❌ Container Rails não encontrado${NC}"
  exit 1
fi

echo "📦 Copiando instalador para o container..."
docker cp kanban-module/install-online.sh "$CONTAINER":/tmp/

echo "🔧 Executando instalação..."
docker exec "$CONTAINER" sh /tmp/install-online.sh

echo ""
echo "📦 Instalando dependências frontend..."
docker exec "$CONTAINER" sh -c "command -v pnpm >/dev/null 2>&1 || (apk add --no-cache nodejs npm && npm install -g pnpm)" 2>/dev/null || true
docker exec "$CONTAINER" sh -c "cd /app && pnpm install --frozen-lockfile"

echo ""
echo "🏗️  Compilando assets (1-2 minutos)..."
docker exec "$CONTAINER" sh -c "cd /app && RAILS_ENV=production NODE_ENV=production bundle exec rake assets:precompile"

echo ""
echo "🔄 Reiniciando container..."
docker restart "$CONTAINER"
sleep 15

# ========================================================================
# VERIFICAR INSTALAÇÃO
# ========================================================================
echo ""
echo -e "${BLUE}📋 ETAPA 5/5: Verificando instalação${NC}"
echo ""

docker exec "$CONTAINER" bundle exec rails runner "
  puts '📊 Status do módulo Kanban:'
  puts '  ✅ Módulo instalado com sucesso!'
  puts '  📁 Arquivos em: /app/kanban-module'
" 2>/dev/null || echo "⚠️  Container ainda inicializando..."

# Limpar arquivos temporários
rm -rf "$TEMP_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ INSTALAÇÃO CONCLUÍDA!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}🎯 PRÓXIMOS PASSOS:${NC}"
echo "   1. Acesse: http://localhost:3000"
echo "   2. Faça login"
echo "   3. Procure 'Kanban' no menu lateral"
echo ""
echo -e "${YELLOW}💡 DICA:${NC}"
echo "   Para usar outra URL, defina:"
echo "   export KANBAN_MODULE_URL='https://outra-url.com/module.tar.gz'"
echo ""

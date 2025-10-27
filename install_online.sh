#!/bin/bash

# ========================================================================
# INSTALADOR ONLINE DO MÓDULO KANBAN PARA CHATWOOT
# ========================================================================
# Baixa e instala o módulo Kanban direto do GitHub
# Uso: ./install_online.sh [VERSION]
# Exemplo: ./install_online.sh v1.0.0
# ========================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ========================================================================
# CONFIGURAÇÃO
# ========================================================================
GITHUB_USER="SEU_USUARIO"  # ← ALTERE AQUI
GITHUB_REPO="SEU_REPO"     # ← ALTERE AQUI
VERSION=${1:-"latest"}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🚀 INSTALADOR ONLINE DO MÓDULO KANBAN${NC}"
echo -e "${BLUE}GitHub: ${GITHUB_USER}/${GITHUB_REPO}${NC}"
echo -e "${BLUE}Versão: ${VERSION}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ========================================================================
# VERIFICAR PRÉ-REQUISITOS
# ========================================================================
echo -e "${BLUE}📋 Verificando pré-requisitos...${NC}"
echo ""

# Verificar se docker está instalado
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}❌ Docker não encontrado. Instale o Docker primeiro.${NC}"
  exit 1
fi

# Verificar se docker compose está instalado
if ! docker compose version >/dev/null 2>&1; then
  echo -e "${RED}❌ Docker Compose não encontrado. Instale o Docker Compose primeiro.${NC}"
  exit 1
fi

# Verificar se curl ou wget está disponível
if command -v curl >/dev/null 2>&1; then
  DOWNLOAD_CMD="curl -fsSL"
elif command -v wget >/dev/null 2>&1; then
  DOWNLOAD_CMD="wget -qO-"
else
  echo -e "${RED}❌ curl ou wget não encontrado. Instale um deles primeiro.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Pré-requisitos verificados${NC}"
echo ""

# ========================================================================
# ETAPA 1: Baixar módulo do GitHub
# ========================================================================
echo -e "${BLUE}📋 ETAPA 1/5: Baixando módulo do GitHub${NC}"
echo ""

# Determinar URL de download
if [ "$VERSION" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/releases/latest/download/chatwoot-kanban-module.tar.gz"
else
  DOWNLOAD_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/releases/download/${VERSION}/chatwoot-kanban-module-${VERSION}.tar.gz"
fi

echo "📥 Baixando de: $DOWNLOAD_URL"

# Criar diretório temporário
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Baixar tarball
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$DOWNLOAD_URL" -o kanban-module.tar.gz
else
  wget -qO kanban-module.tar.gz "$DOWNLOAD_URL"
fi

# Verificar se o download foi bem-sucedido
if [ ! -f "kanban-module.tar.gz" ] || [ ! -s "kanban-module.tar.gz" ]; then
  echo -e "${RED}❌ Falha ao baixar o módulo. Verifique a URL e a versão.${NC}"
  echo -e "${YELLOW}URL tentada: $DOWNLOAD_URL${NC}"
  exit 1
fi

DOWNLOAD_SIZE=$(du -h kanban-module.tar.gz | cut -f1)
echo -e "${GREEN}✅ Módulo baixado (${DOWNLOAD_SIZE})${NC}"
echo ""

# ========================================================================
# ETAPA 2: Extrair módulo
# ========================================================================
echo -e "${BLUE}📋 ETAPA 2/5: Extraindo módulo${NC}"
echo ""

tar -xzf kanban-module.tar.gz

if [ ! -d "kanban-module" ]; then
  echo -e "${RED}❌ Falha ao extrair o módulo${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Módulo extraído${NC}"
echo ""

# ========================================================================
# ETAPA 3: Configurar Docker Compose
# ========================================================================
echo -e "${BLUE}📋 ETAPA 3/5: Configurando Docker Compose${NC}"
echo ""

# Voltar para o diretório original (onde está o docker-compose.yaml)
cd - >/dev/null

# Copiar módulo para o diretório atual
cp -r "$TEMP_DIR/kanban-module" .

# Criar docker-compose.override.yaml
cat > docker-compose.override.yaml << 'EOF'
version: '3'

services:
  base: &base
    volumes:
      - ./kanban-module:/kanban-module:ro

  rails:
    <<: *base
  
  sidekiq:
    <<: *base
EOF

echo -e "${GREEN}✅ Docker Compose configurado${NC}"
echo ""

# ========================================================================
# ETAPA 4: Instalar módulo no container
# ========================================================================
echo -e "${BLUE}📋 ETAPA 4/5: Instalando módulo${NC}"
echo ""

# Detectar container Rails
CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "rails" | grep -v "sidekiq" | head -n 1)

if [ -z "$CONTAINER" ]; then
  echo -e "${YELLOW}⚠️  Container Rails não encontrado. Iniciando containers...${NC}"
  docker compose up -d
  sleep 30
  CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "rails" | grep -v "sidekiq" | head -n 1)
fi

if [ -z "$CONTAINER" ]; then
  echo -e "${RED}❌ Não foi possível encontrar o container Rails${NC}"
  exit 1
fi

echo "🎯 Container detectado: $CONTAINER"

# Copiar módulo para o container
docker cp kanban-module "$CONTAINER":/app/

# Criar e executar script de instalação interno
cat > /tmp/install-kanban.sh << 'INSTALL_SCRIPT'
#!/bin/sh
set -e

echo "🔧 Instalando módulo Kanban..."

# Copiar controllers
cp -r /app/kanban-module/controllers/* /app/app/controllers/api/v1/accounts/ 2>/dev/null || true

# Copiar models
cp -r /app/kanban-module/models/* /app/app/models/ 2>/dev/null || true

# Copiar helpers
mkdir -p /app/app/helpers/api/v1/accounts/kanban
cp -r /app/kanban-module/helpers/kanban/* /app/app/helpers/api/v1/accounts/kanban/ 2>/dev/null || true

# Copiar serializers
cp -r /app/kanban-module/serializers/* /app/app/serializers/ 2>/dev/null || true

# Copiar policies
cp -r /app/kanban-module/policies/* /app/app/policies/ 2>/dev/null || true

# Copiar views (jbuilders)
echo "📋 Copiando views JBuilder..."
mkdir -p /app/app/views/api/v1/accounts/products
mkdir -p /app/app/views/api/v1/accounts/kanban_cards/products
mkdir -p /app/app/views/api/v1/accounts/conversations/products
mkdir -p /app/app/views/api/v1/accounts/conversations/funnels
mkdir -p /app/app/views/api/v1/accounts/conversations/followers

if [ -d "/app/kanban-module/views/products" ]; then
  cp /app/kanban-module/views/products/*.jbuilder /app/app/views/api/v1/accounts/products/ 2>/dev/null && echo "  ✅ Views de products copiadas" || echo "  ⚠️  Sem views de products"
fi
if [ -d "/app/kanban-module/views/kanban_cards" ]; then
  cp /app/kanban-module/views/kanban_cards/products/*.jbuilder /app/app/views/api/v1/accounts/kanban_cards/products/ 2>/dev/null && echo "  ✅ Views de kanban_cards/products copiadas" || echo "  ⚠️  Sem views de kanban_cards"
fi
if [ -d "/app/kanban-module/views/conversations" ]; then
  cp /app/kanban-module/views/conversations/products/*.jbuilder /app/app/views/api/v1/accounts/conversations/products/ 2>/dev/null && echo "  ✅ Views de conversations/products copiadas" || echo "  ⚠️  Sem views de conversations/products"
  cp /app/kanban-module/views/conversations/funnels/*.jbuilder /app/app/views/api/v1/accounts/conversations/funnels/ 2>/dev/null && echo "  ✅ Views de conversations/funnels copiadas" || echo "  ⚠️  Sem views de conversations/funnels"
  cp /app/kanban-module/views/conversations/followers/*.jbuilder /app/app/views/api/v1/accounts/conversations/followers/ 2>/dev/null && echo "  ✅ Views de conversations/followers copiadas" || echo "  ⚠️  Sem views de conversations/followers"
fi

# Copiar services
cp -r /app/kanban-module/services/* /app/app/services/ 2>/dev/null || true

# Copiar frontend
mkdir -p /app/app/javascript/dashboard/routes/dashboard/kanban
cp -r /app/kanban-module/frontend/routes/dashboard/kanban/* /app/app/javascript/dashboard/routes/dashboard/kanban/ 2>/dev/null || true
mkdir -p /app/app/javascript/dashboard/routes/dashboard/settings/products
cp -r /app/kanban-module/frontend/routes/settings/products/* /app/app/javascript/dashboard/routes/dashboard/settings/products/ 2>/dev/null || true
mkdir -p /app/app/javascript/dashboard/routes/dashboard/settings/notifications
cp /app/kanban-module/frontend/routes/settings/notifications/KanbanNotificationSettings.vue /app/app/javascript/dashboard/routes/dashboard/settings/notifications/ 2>/dev/null || true
cp -r /app/kanban-module/frontend/store/modules/* /app/app/javascript/dashboard/store/modules/ 2>/dev/null || true
cp -r /app/kanban-module/frontend/api/* /app/app/javascript/dashboard/api/ 2>/dev/null || true
cp -r /app/kanban-module/frontend/composables/* /app/app/javascript/dashboard/composables/ 2>/dev/null || true
cp /app/kanban-module/frontend/components/conversation/ConversationFunnels.vue /app/app/javascript/dashboard/routes/dashboard/conversation/ 2>/dev/null || true
mkdir -p /app/app/javascript/dashboard/components-next/Contacts/ContactsSidebar
cp /app/kanban-module/frontend/components/contacts/ContactProducts.vue /app/app/javascript/dashboard/components-next/Contacts/ContactsSidebar/ 2>/dev/null || true
mkdir -p /app/app/javascript/dashboard/components/widgets
cp /app/kanban-module/frontend/components/widgets/AutomationFunnelColumnInput.vue /app/app/javascript/dashboard/components/widgets/ 2>/dev/null || true
mkdir -p /app/app/javascript/dashboard/components-next/Conversation/ConversationCard
cp /app/kanban-module/frontend/components/conversation-card/CardFunnels.vue /app/app/javascript/dashboard/components-next/Conversation/ConversationCard/ 2>/dev/null || true
cp /app/kanban-module/frontend/components/conversation-card/CardFunnel.vue /app/app/javascript/dashboard/components-next/Conversation/ConversationCard/ 2>/dev/null || true
cp -r /app/kanban-module/frontend/i18n/locale/en/*.json /app/app/javascript/dashboard/i18n/locale/en/ 2>/dev/null || true
cp -r /app/kanban-module/frontend/i18n/locale/pt_BR/*.json /app/app/javascript/dashboard/i18n/locale/pt_BR/ 2>/dev/null || true

# Copiar migrations
cp /app/kanban-module/migrations/* /app/db/migrate/ 2>/dev/null || true

# Copiar Sidebar.vue
echo "📋 Copiando Sidebar.vue..."
cp /app/kanban-module/frontend/components/sidebar/Sidebar.vue /app/app/javascript/dashboard/components-next/sidebar/Sidebar.vue 2>/dev/null || true

# Aplicar patches
if [ -d "/app/kanban-module/patches" ]; then
  cd /app/kanban-module/patches
  chmod +x *.sh *.rb 2>/dev/null || true
  sh apply-patches.sh 2>/dev/null || echo "⚠️  Alguns patches já aplicados"
fi

cd /app

# Patch: Adicionar rotas do Kanban
echo "🔧 Aplicando patch de rotas do Kanban..."
DASHBOARD_ROUTES="/app/app/javascript/dashboard/routes/dashboard/dashboard.routes.js"
if ! grep -A 20 "children: \[" "$DASHBOARD_ROUTES" | grep -q "...kanbanRoutes"; then
  sed -i '/...campaignsRoutes.routes,/a\        ...kanbanRoutes,' "$DASHBOARD_ROUTES"
  echo "  ✅ Rotas do Kanban adicionadas"
fi

# Patch: Adicionar rotas de produtos
echo "🔧 Aplicando patch de rotas de produtos..."
SETTINGS_ROUTES="/app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js"
if ! grep -q "import products from" "$SETTINGS_ROUTES"; then
  sed -i "/import reports from/a\import products from './products/products.routes';" "$SETTINGS_ROUTES"
  sed -i '/...reports.routes,/a\    ...products.routes,' "$SETTINGS_ROUTES"
  echo "  ✅ Rotas de produtos adicionadas"
fi

# Patch: Adicionar traduções EN
echo "🔧 Aplicando patch de traduções EN..."
I18N_EN="/app/app/javascript/dashboard/i18n/locale/en/index.js"
if ! grep -q "import kanban from" "$I18N_EN"; then
  sed -i "/import mfa from/a\import kanban from './kanban.json';" "$I18N_EN"
  sed -i "/import kanban from/a\import productsMgmt from './productsMgmt.json';" "$I18N_EN"
  sed -i '/...mfa,/a\  ...kanban,' "$I18N_EN"
  sed -i '/...kanban,/a\  ...productsMgmt,' "$I18N_EN"
  echo "  ✅ Traduções EN adicionadas"
fi

# Patch: Adicionar traduções PT-BR
echo "🔧 Aplicando patch de traduções PT-BR..."
I18N_PT="/app/app/javascript/dashboard/i18n/locale/pt_BR/index.js"
if ! grep -q "import kanban from" "$I18N_PT"; then
  sed -i "/import whatsappTemplates from/a\import kanban from './kanban.json';" "$I18N_PT"
  sed -i "/import kanban from/a\import productsMgmt from './productsMgmt.json';" "$I18N_PT"
  sed -i '/...whatsappTemplates,/a\  ...kanban,' "$I18N_PT"
  sed -i '/...kanban,/a\  ...productsMgmt,' "$I18N_PT"
  echo "  ✅ Traduções PT-BR adicionadas"
fi

# Patch: Registrar store modules
echo "🔧 Aplicando patch de store modules..."
STORE_INDEX="/app/app/javascript/dashboard/store/index.js"
if ! grep -q "import products from './modules/products'" "$STORE_INDEX"; then
  sed -i "/import portals from/a\import products from './modules/products';" "$STORE_INDEX"
  sed -i "/import products from/a\import conversationProducts from './modules/conversationProducts';" "$STORE_INDEX"
  sed -i "/import conversationProducts from/a\import kanbanCardProducts from './modules/kanbanCardProducts';" "$STORE_INDEX"
  sed -i "/import kanbanCardProducts from/a\import conversationFunnels from './modules/conversationFunnels';" "$STORE_INDEX"
  sed -i '/    portals,/a\    products,' "$STORE_INDEX"
  sed -i '/    products,/a\    conversationProducts,' "$STORE_INDEX"
  sed -i '/    conversationProducts,/a\    kanbanCardProducts,' "$STORE_INDEX"
  sed -i '/    kanbanCardProducts,/a\    conversationFunnels,' "$STORE_INDEX"
  echo "  ✅ Store modules registrados"
fi

# Patch: Copiar mutation-types.js
echo "🔧 Copiando mutation-types.js atualizado..."
if [ -f "/app/kanban-module/frontend/mutation-types.js" ]; then
  cp /app/kanban-module/frontend/mutation-types.js /app/app/javascript/dashboard/store/mutation-types.js
  echo "  ✅ Mutation types atualizados"
fi

# Executar migrations
echo "🔧 Executando migrations..."
bundle exec rails db:migrate

echo "✅ Módulo Kanban instalado!"
INSTALL_SCRIPT

docker cp /tmp/install-kanban.sh "$CONTAINER":/tmp/
docker exec "$CONTAINER" sh /tmp/install-kanban.sh

# ========================================================================
# ETAPA 5: Compilar assets
# ========================================================================
echo ""
echo -e "${BLUE}📋 ETAPA 5/5: Compilando assets${NC}"
echo ""

echo "📦 Instalando dependências..."
docker exec "$CONTAINER" sh -c "command -v pnpm >/dev/null 2>&1 || (apk add --no-cache nodejs npm && npm install -g pnpm)"
docker exec "$CONTAINER" sh -c "cd /app && pnpm install --frozen-lockfile"

echo ""
echo "🏗️  Compilando assets (isso vai demorar 1-2 minutos)..."
docker exec "$CONTAINER" sh -c "cd /app && RAILS_ENV=production NODE_ENV=production bundle exec rake assets:precompile"

echo ""
echo "🔄 Reiniciando container..."
docker restart "$CONTAINER"

sleep 15

# ========================================================================
# VERIFICAR INSTALAÇÃO
# ========================================================================
echo ""
echo -e "${BLUE}📊 Verificando instalação${NC}"
echo ""

docker exec "$CONTAINER" bundle exec rails runner "
  puts '📊 Verificando módulo Kanban:'
  puts '  ✅ Pipelines: ' + KanbanPipeline.count.to_s
  puts '  ✅ Colunas: ' + KanbanColumn.count.to_s
  puts '  ✅ Cards: ' + KanbanCard.count.to_s
  puts '  ✅ Produtos: ' + Product.count.to_s
" 2>/dev/null || echo "⚠️  Aguarde o container iniciar completamente"

# Limpar arquivos temporários
rm -rf "$TEMP_DIR"
rm -f /tmp/install-kanban.sh

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ INSTALAÇÃO CONCLUÍDA!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}🎯 PRÓXIMOS PASSOS:${NC}"
echo "   1. Acesse: http://localhost:3000"
echo "   2. Faça login"
echo "   3. Limpe o cache do navegador (Ctrl+Shift+R)"
echo "   4. Procure 'CRM Kanban' no menu lateral"
echo ""
echo -e "${YELLOW}📝 NOTA:${NC}"
echo "   O módulo foi instalado na versão: ${VERSION}"
echo "   Para atualizar, execute novamente com uma nova versão."
echo ""


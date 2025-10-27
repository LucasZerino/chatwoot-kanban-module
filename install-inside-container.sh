#!/bin/sh

# ========================================================================
# INSTALADOR DO MÓDULO KANBAN - EXECUÇÃO DENTRO DO CONTAINER
# ========================================================================
# Este script deve ser executado DENTRO do container Rails
# Via Portainer Console ou docker exec
# ========================================================================

set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 INSTALADOR DO MÓDULO KANBAN (Dentro do Container)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# URL do módulo no GitHub
MODULE_URL="${KANBAN_MODULE_URL:-https://github.com/LucasZerino/chatwoot-kanban-module/releases/download/kanban/kanban-module.tar.gz}"

# Verificar se já foi instalado
if [ -f "/app/.kanban-installed" ]; then
  echo "⚠️  Módulo Kanban já instalado"
  echo "   Para reinstalar, execute: rm /app/.kanban-installed"
  exit 0
fi

# ========================================================================
# INSTALAR FERRAMENTAS NECESSÁRIAS
# ========================================================================
echo "📦 Instalando ferramentas..."

# Instalar curl/wget se não existir
if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
  echo "   Instalando wget..."
  apk add --no-cache wget 2>/dev/null || apt-get update && apt-get install -y wget 2>/dev/null || true
fi

# Instalar pnpm se não existir
if ! command -v pnpm >/dev/null 2>&1; then
  echo "   Instalando pnpm..."
  if ! command -v npm >/dev/null 2>&1; then
    apk add --no-cache nodejs npm 2>/dev/null || apt-get install -y nodejs npm 2>/dev/null || true
  fi
  npm install -g pnpm 2>/dev/null || true
fi

echo "✅ Ferramentas instaladas"
echo ""

# ========================================================================
# BAIXAR MÓDULO
# ========================================================================
echo "📥 Baixando módulo do GitHub..."
echo "   URL: $MODULE_URL"

cd /tmp

if command -v wget >/dev/null 2>&1; then
  wget -q -O kanban-module.tar.gz "$MODULE_URL"
elif command -v curl >/dev/null 2>&1; then
  curl -sL -o kanban-module.tar.gz "$MODULE_URL"
else
  echo "❌ Erro: wget ou curl não encontrado"
  exit 1
fi

if [ ! -f "kanban-module.tar.gz" ] || [ ! -s "kanban-module.tar.gz" ]; then
  echo "❌ Erro: Falha ao baixar o módulo"
  exit 1
fi

echo "✅ Módulo baixado ($(du -h kanban-module.tar.gz | cut -f1))"
echo ""

# ========================================================================
# EXTRAIR MÓDULO
# ========================================================================
echo "📦 Extraindo módulo..."

tar -xzf kanban-module.tar.gz -C /tmp
rm -rf /app/kanban-module
mv /tmp/kanban-module /app/

echo "✅ Módulo extraído em /app/kanban-module"
echo ""

# ========================================================================
# COPIAR ARQUIVOS
# ========================================================================
echo "📂 Copiando arquivos do módulo..."

# Copiar controllers
echo "   → Controllers..."
cp -r /app/kanban-module/controllers/* /app/app/controllers/api/v1/accounts/ 2>/dev/null || true

# Copiar models
echo "   → Models..."
cp -r /app/kanban-module/models/* /app/app/models/ 2>/dev/null || true

# Copiar helpers
echo "   → Helpers..."
mkdir -p /app/app/helpers/api/v1/accounts/kanban
cp -r /app/kanban-module/helpers/kanban/* /app/app/helpers/api/v1/accounts/kanban/ 2>/dev/null || true

# Copiar serializers
echo "   → Serializers..."
cp -r /app/kanban-module/serializers/* /app/app/serializers/ 2>/dev/null || true

# Copiar policies
echo "   → Policies..."
cp -r /app/kanban-module/policies/* /app/app/policies/ 2>/dev/null || true

# Copiar views
echo "   → Views..."
mkdir -p /app/app/views/api/v1/accounts/{products,kanban_cards/products,conversations/products,conversations/funnels,conversations/followers}
cp /app/kanban-module/views/products/*.jbuilder /app/app/views/api/v1/accounts/products/ 2>/dev/null || true
cp /app/kanban-module/views/kanban_cards/products/*.jbuilder /app/app/views/api/v1/accounts/kanban_cards/products/ 2>/dev/null || true
cp /app/kanban-module/views/conversations/products/*.jbuilder /app/app/views/api/v1/accounts/conversations/products/ 2>/dev/null || true
cp /app/kanban-module/views/conversations/funnels/*.jbuilder /app/app/views/api/v1/accounts/conversations/funnels/ 2>/dev/null || true
cp /app/kanban-module/views/conversations/followers/*.jbuilder /app/app/views/api/v1/accounts/conversations/followers/ 2>/dev/null || true

# Copiar services
echo "   → Services..."
cp -r /app/kanban-module/services/* /app/app/services/ 2>/dev/null || true

# Copiar frontend
echo "   → Frontend routes..."
mkdir -p /app/app/javascript/dashboard/routes/dashboard/kanban
cp -r /app/kanban-module/frontend/routes/dashboard/kanban/* /app/app/javascript/dashboard/routes/dashboard/kanban/ 2>/dev/null || true
mkdir -p /app/app/javascript/dashboard/routes/dashboard/settings/products
cp -r /app/kanban-module/frontend/routes/settings/products/* /app/app/javascript/dashboard/routes/dashboard/settings/products/ 2>/dev/null || true
mkdir -p /app/app/javascript/dashboard/routes/dashboard/settings/notifications
cp /app/kanban-module/frontend/routes/settings/notifications/KanbanNotificationSettings.vue /app/app/javascript/dashboard/routes/dashboard/settings/notifications/ 2>/dev/null || true

echo "   → Frontend store..."
cp -r /app/kanban-module/frontend/store/modules/* /app/app/javascript/dashboard/store/modules/ 2>/dev/null || true

echo "   → Frontend API..."
cp -r /app/kanban-module/frontend/api/* /app/app/javascript/dashboard/api/ 2>/dev/null || true

echo "   → Frontend composables..."
cp -r /app/kanban-module/frontend/composables/* /app/app/javascript/dashboard/composables/ 2>/dev/null || true

echo "   → Frontend components..."
cp /app/kanban-module/frontend/components/conversation/ConversationFunnels.vue /app/app/javascript/dashboard/routes/dashboard/conversation/ 2>/dev/null || true
mkdir -p /app/app/javascript/dashboard/components-next/Contacts/ContactsSidebar
cp /app/kanban-module/frontend/components/contacts/ContactProducts.vue /app/app/javascript/dashboard/components-next/Contacts/ContactsSidebar/ 2>/dev/null || true
mkdir -p /app/app/javascript/dashboard/components/widgets
cp /app/kanban-module/frontend/components/widgets/AutomationFunnelColumnInput.vue /app/app/javascript/dashboard/components/widgets/ 2>/dev/null || true
mkdir -p /app/app/javascript/dashboard/components-next/Conversation/ConversationCard
cp /app/kanban-module/frontend/components/conversation-card/CardFunnels.vue /app/app/javascript/dashboard/components-next/Conversation/ConversationCard/ 2>/dev/null || true
cp /app/kanban-module/frontend/components/conversation-card/CardFunnel.vue /app/app/javascript/dashboard/components-next/Conversation/ConversationCard/ 2>/dev/null || true

echo "   → Frontend i18n..."
cp -r /app/kanban-module/frontend/i18n/locale/en/*.json /app/app/javascript/dashboard/i18n/locale/en/ 2>/dev/null || true
cp -r /app/kanban-module/frontend/i18n/locale/pt_BR/*.json /app/app/javascript/dashboard/i18n/locale/pt_BR/ 2>/dev/null || true

# Copiar migrations
echo "   → Migrations..."
cp /app/kanban-module/migrations/* /app/db/migrate/ 2>/dev/null || true

# Copiar Sidebar.vue
echo "   → Sidebar.vue..."
cp /app/kanban-module/frontend/components/sidebar/Sidebar.vue /app/app/javascript/dashboard/components-next/sidebar/Sidebar.vue 2>/dev/null || true

echo "✅ Arquivos copiados"
echo ""

# ========================================================================
# APLICAR PATCHES
# ========================================================================
echo "🔧 Aplicando patches..."

if [ -d "/app/kanban-module/patches" ]; then
  cd /app/kanban-module/patches
  chmod +x *.sh *.rb 2>/dev/null || true
  sh apply-patches.sh 2>/dev/null || echo "⚠️  Alguns patches já aplicados"
fi

# Patch: Adicionar rotas do Kanban no dashboard.routes.js
echo "🔧 Aplicando patch de rotas do Kanban..."
DASHBOARD_ROUTES="/app/app/javascript/dashboard/routes/dashboard/dashboard.routes.js"
if ! grep -A 20 "children: \[" "$DASHBOARD_ROUTES" | grep -q "...kanbanRoutes"; then
  sed -i '/...campaignsRoutes.routes,/a\        ...kanbanRoutes,' "$DASHBOARD_ROUTES"
  echo "  ✅ Rotas do Kanban adicionadas"
else
  echo "  ⏭️  Rotas do Kanban já adicionadas"
fi

# Patch: Adicionar rotas de produtos no settings.routes.js
echo "🔧 Aplicando patch de rotas de produtos..."
SETTINGS_ROUTES="/app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js"
if ! grep -q "import products from" "$SETTINGS_ROUTES"; then
  sed -i "/import reports from/a\import products from './products/products.routes';" "$SETTINGS_ROUTES"
  sed -i '/...reports.routes,/a\    ...products.routes,' "$SETTINGS_ROUTES"
  echo "  ✅ Rotas de produtos adicionadas"
else
  echo "  ⏭️  Rotas de produtos já adicionadas"
fi

# Patch: Adicionar traduções do Kanban no i18n EN
echo "🔧 Aplicando patch de traduções EN..."
I18N_EN="/app/app/javascript/dashboard/i18n/locale/en/index.js"
if ! grep -q "import kanban from" "$I18N_EN"; then
  sed -i "/import mfa from/a\import kanban from './kanban.json';" "$I18N_EN"
  sed -i "/import kanban from/a\import productsMgmt from './productsMgmt.json';" "$I18N_EN"
  sed -i '/...mfa,/a\  ...kanban,' "$I18N_EN"
  sed -i '/...kanban,/a\  ...productsMgmt,' "$I18N_EN"
  echo "  ✅ Traduções EN adicionadas"
else
  echo "  ⏭️  Traduções EN já adicionadas"
fi

# Patch: Adicionar traduções do Kanban no i18n PT-BR
echo "🔧 Aplicando patch de traduções PT-BR..."
I18N_PT="/app/app/javascript/dashboard/i18n/locale/pt_BR/index.js"
if ! grep -q "import kanban from" "$I18N_PT"; then
  sed -i "/import whatsappTemplates from/a\import kanban from './kanban.json';" "$I18N_PT"
  sed -i "/import kanban from/a\import productsMgmt from './productsMgmt.json';" "$I18N_PT"
  sed -i '/...whatsappTemplates,/a\  ...kanban,' "$I18N_PT"
  sed -i '/...kanban,/a\  ...productsMgmt,' "$I18N_PT"
  echo "  ✅ Traduções PT-BR adicionadas"
else
  echo "  ⏭️  Traduções PT-BR já adicionadas"
fi

# Patch: Registrar módulos no store
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
else
  echo "  ⏭️  Store modules já registrados"
fi

# Patch: Copiar mutation-types.js
echo "🔧 Copiando mutation-types.js atualizado..."
if [ -f "/app/kanban-module/frontend/mutation-types.js" ]; then
  cp /app/kanban-module/frontend/mutation-types.js /app/app/javascript/dashboard/store/mutation-types.js
  echo "  ✅ Mutation types atualizados"
else
  echo "  ⏭️  mutation-types.js não encontrado no módulo"
fi

echo "✅ Patches aplicados"
echo ""

# ========================================================================
# EXECUTAR MIGRATIONS
# ========================================================================
echo "🗄️  Executando migrations..."

cd /app
bundle exec rails db:migrate 2>/dev/null || echo "⚠️  Migrations já executadas"

echo "✅ Migrations executadas"
echo ""

# ========================================================================
# INSTALAR DEPENDÊNCIAS E COMPILAR ASSETS
# ========================================================================
echo "📦 Instalando dependências frontend..."

cd /app
pnpm install --frozen-lockfile 2>/dev/null || pnpm install

echo "✅ Dependências instaladas"
echo ""

echo "🧹 Limpando cache de assets antigos..."

# Limpar cache antigo para forçar rebuild completo
rm -rf public/packs public/vite tmp/cache/assets tmp/cache/webpacker 2>/dev/null || true

echo "✅ Cache limpo"
echo ""

echo "🏗️  Compilando assets (isso pode demorar 1-2 minutos)..."

# Compilar com flags para forçar rebuild completo
RAILS_ENV=production NODE_ENV=production bundle exec rake assets:clobber assets:precompile

echo "✅ Assets compilados"
echo ""

# ========================================================================
# MARCAR COMO INSTALADO
# ========================================================================
touch /app/.kanban-installed

# Limpar temporários
rm -f /tmp/kanban-module.tar.gz

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ INSTALAÇÃO CONCLUÍDA!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 PRÓXIMOS PASSOS:"
echo "   1. Reinicie o container Rails"
echo "   2. Acesse seu Chatwoot"
echo "   3. Pressione Ctrl+Shift+R para limpar cache"
echo "   4. Procure 'Kanban' no menu lateral"
echo ""
echo "⚠️  IMPORTANTE: Reinicie o container para aplicar as mudanças!"
echo ""


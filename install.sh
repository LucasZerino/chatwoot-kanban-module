#!/bin/bash
# Instalador Ultra-Simples do Módulo Kanban para Chatwoot
# USO: curl -s https://seu-repo.com/install.sh | bash

set -e

echo "================================================================================"
echo "🚀 INSTALADOR DO MÓDULO KANBAN PARA CHATWOOT"
echo "================================================================================"
echo ""

# Detectar ambiente
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    DOCKER_COMPOSE_CMD="docker-compose"
    CONTAINER_NAME="rails"
elif command -v docker &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
    CONTAINER_NAME="rails"
else
    echo "❌ Docker não encontrado!"
    exit 1
fi

echo "✓ Docker detectado"

# Baixar bundle
echo ""
echo "📥 Baixando módulo Kanban..."
# Detecta automaticamente a URL base do script
SCRIPT_URL="${BASH_SOURCE[0]}"
if [[ "$SCRIPT_URL" == http* ]]; then
    BASE_URL=$(dirname "$SCRIPT_URL")
    BUNDLE_URL="$BASE_URL/kanban_module_bundle.txt"
else
    # Fallback: URL fixa do repositório LucasZerino/chatwoot-kanban-module
    BUNDLE_URL="https://raw.githubusercontent.com/LucasZerino/chatwoot-kanban-module/main/bundle.txt"
fi

echo "  URL: $BUNDLE_URL"

if ! BUNDLE_CONTENT=$(curl -sL "$BUNDLE_URL"); then
    echo "❌ Erro ao baixar bundle!"
    echo "   Verifique sua conexão com internet"
    exit 1
fi

echo "✓ Bundle baixado ($(echo -n "$BUNDLE_CONTENT" | wc -c) caracteres)"

# Criar arquivo temporário de instalação
echo ""
echo "🔧 Preparando instalação..."

cat > /tmp/kanban_install.rb << 'EOF'
# Criar ou atualizar config
config = InstallationConfig.find_or_initialize_by(name: 'MODULE_KANBAN_BUNDLE')
config.value = ENV['BUNDLE_CONTENT']
config.locked = false
config.save!

Rails.logger.info "✓ Config salvo no banco"

# Decodificar e executar bundle
require 'base64'
require 'zlib'
require 'json'

Rails.logger.info "📦 Decodificando bundle..."
decoded = Base64.decode64(config.value)
decompressed = Zlib::Inflate.inflate(decoded)
bundle = JSON.parse(decompressed)

Rails.logger.info "✓ Bundle: #{bundle['name']} v#{bundle['version']}"
Rails.logger.info "✓ Arquivos: #{bundle['files']&.keys&.length || 0}"

if bundle['install_script']
  Rails.logger.info "▶️  Executando instalação..."
  eval(bundle['install_script'])
else
  Rails.logger.error "❌ Install script não encontrado!"
  exit 1
end
EOF

echo "✓ Script de instalação criado"

# Executar instalação
echo ""
echo "⚙️  Instalando módulo..."
echo ""

BUNDLE_CONTENT="$BUNDLE_CONTENT" $DOCKER_COMPOSE_CMD exec -T $CONTAINER_NAME bundle exec rails runner - < /tmp/kanban_install.rb

INSTALL_EXIT=$?

if [ $INSTALL_EXIT -ne 0 ]; then
    echo ""
    echo "❌ Erro na instalação!"
    echo "   Veja os logs acima para detalhes"
    exit 1
fi

# Limpar arquivo temporário
rm -f /tmp/kanban_install.rb

# Reiniciar
echo ""
echo "🔄 Reiniciando servidor..."
$DOCKER_COMPOSE_CMD restart $CONTAINER_NAME

echo ""
echo "================================================================================"
echo "✅ MÓDULO KANBAN INSTALADO COM SUCESSO!"
echo "================================================================================"
echo ""
echo "📋 Próximos passos:"
echo "   1. Aguarde 60 segundos para o servidor inicializar"
echo "   2. Acesse: http://localhost:3000/app"
echo "   3. Procure 'Kanban' no menu lateral"
echo "   4. Pronto! Comece a usar!"
echo ""
echo "📞 Suporte: suporte@seu-dominio.com"
echo ""


#!/bin/bash
# Instalador Módulo Kanban v2 - Tudo dentro do container
set -e

echo "================================================================================"
echo "🚀 INSTALADOR DO MÓDULO KANBAN PARA CHATWOOT v2"
echo "================================================================================"
echo ""

# Detectar docker-compose
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    DC="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DC="docker compose"
else
    echo "❌ Docker Compose não encontrado!"
    exit 1
fi

echo "✓ Docker Compose detectado: $DC"

# URL do bundle
BUNDLE_URL="https://raw.githubusercontent.com/LucasZerino/chatwoot-kanban-module/main/bundle.txt"

echo ""
echo "📦 Instalando módulo (tudo dentro do container)..."
echo ""

# Executar TUDO dentro do container em 1 comando
$DC exec -T rails sh << 'CONTAINERSCRIPT'
set -e

echo "📥 Baixando bundle..."
ruby -ropen-uri -e "File.write('/tmp/kanban.txt', URI.open('https://raw.githubusercontent.com/LucasZerino/chatwoot-kanban-module/main/bundle.txt').read)"
echo "✓ Bundle baixado: $(wc -c < /tmp/kanban.txt) bytes"

echo ""
echo "🔧 Criando instalador..."
cat > /tmp/install.rb << 'RUBYSCRIPT'
bundle_text = File.read('/tmp/kanban.txt')

Rails.logger.info '=' * 80
Rails.logger.info '🚀 INSTALANDO MÓDULO KANBAN'
Rails.logger.info '=' * 80

# Salvar config no banco
config = InstallationConfig.find_or_initialize_by(name: 'MODULE_KANBAN_BUNDLE')
config.value = bundle_text
config.locked = false
config.save!
Rails.logger.info '✓ Config salvo'

# Decodificar
require 'base64'
require 'zlib'
require 'json'

decoded = Base64.decode64(config.value)
Rails.logger.info "✓ Decodificado: #{decoded.length} bytes"

decompressed = Zlib::Inflate.inflate(decoded)
Rails.logger.info "✓ Descomprimido: #{decompressed.length} bytes"

bundle = JSON.parse(decompressed)
Rails.logger.info "✓ Bundle: #{bundle['name']} v#{bundle['version']}"

# Executar
if bundle['install_script']
  Rails.logger.info '▶️  Executando instalação...'
  eval(bundle['install_script'])
else
  Rails.logger.error '❌ Sem install_script!'
  exit 1
end

File.delete('/tmp/kanban.txt') rescue nil
RUBYSCRIPT

echo ""
echo "▶️  Executando instalação..."
bundle exec rails runner /tmp/install.rb

rm -f /tmp/install.rb /tmp/kanban.txt
echo ""
echo "✅ Instalação concluída!"
CONTAINERSCRIPT

RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo ""
    echo "❌ Erro na instalação!"
    exit 1
fi

# Limpar e reiniciar
echo ""
echo "🔄 Reiniciando servidor..."
$DC restart rails

echo ""
echo "================================================================================"
echo "✅ MÓDULO KANBAN INSTALADO COM SUCESSO!"
echo "================================================================================"
echo ""
echo "📋 Próximos passos:"
echo "   1. Aguarde 60 segundos"
echo "   2. Acesse: http://localhost:3000/app"
echo "   3. Procure 'Kanban' no menu lateral"
echo ""


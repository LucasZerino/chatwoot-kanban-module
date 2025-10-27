# 🚀 Instalador do Módulo Kanban para Chatwoot

Este instalador adiciona o módulo Kanban completo ao Chatwoot.

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- Uma instalação limpa do Chatwoot rodando
- Acesso ao terminal do host

## 🎯 O que este instalador faz

1. ✅ Copia **todos** os arquivos do módulo Kanban para o container
2. ✅ Aplica patches nos arquivos core do Chatwoot
3. ✅ Executa todas as migrations do banco de dados
4. ✅ Instala dependências (Node.js, pnpm)
5. ✅ Compila os assets do frontend
6. ✅ Reinicia o container

## 📦 Instalação

### Passo 1: Preparar o ambiente

```bash
# Entre na pasta chatwootorigin
cd chatwootorigin

# Prepare o banco de dados (se necessário)
docker compose run --rm rails bundle exec rails db:chatwoot_prepare

# Inicie os containers
docker compose up -d
```

### Passo 2: Executar o instalador

```bash
# Dar permissão de execução
chmod +x install.sh

# Executar o instalador
./install.sh
```

### Passo 3: Aguardar e acessar

1. Aguarde a instalação completar (~2-3 minutos)
2. Acesse `http://localhost:3000`
3. Pressione `Ctrl + Shift + R` para limpar o cache do navegador
4. Procure o menu **"CRM Kanban"** na sidebar

## 📁 Arquivos Instalados

Veja a lista completa de arquivos em: [ARQUIVOS_KANBAN.md](./ARQUIVOS_KANBAN.md)

**Resumo:**
- 🎨 **Frontend**: ~70 arquivos (componentes, rotas, store, API clients)
- ⚙️ **Backend**: ~15 arquivos (controllers, models, helpers)
- 🗄️ **Database**: 30 migrations
- 🔧 **Patches**: 15 arquivos modificados

## 🔧 Troubleshooting

### O menu não aparece

```bash
# Copiar o Sidebar correto
docker cp ../app/javascript/dashboard/components-next/sidebar/Sidebar.vue \
  chatwootorigin-rails-1:/app/app/javascript/dashboard/components-next/sidebar/

# Recompilar
docker exec chatwootorigin-rails-1 sh -c \
  "cd /app && RAILS_ENV=production bundle exec rake assets:precompile"

# Reiniciar
docker restart chatwootorigin-rails-1
```

### Erros no console do navegador

```bash
# Copiar todos os arquivos faltantes
docker cp ../app/javascript/dashboard/routes/dashboard/kanban/ \
  chatwootorigin-rails-1:/app/app/javascript/dashboard/routes/dashboard/

# Recompilar e reiniciar
docker exec chatwootorigin-rails-1 sh -c \
  "cd /app && RAILS_ENV=production bundle exec rake assets:precompile"
docker restart chatwootorigin-rails-1
```

### Verificar logs

```bash
# Ver logs do Rails
docker logs chatwootorigin-rails-1 -f

# Ver logs do Sidekiq
docker logs chatwootorigin-sidekiq-1 -f
```

## 🎨 Estrutura do Módulo

```
kanban-module/
├── controllers/          # Controllers da API
│   ├── kanban_pipelines_controller.rb
│   ├── kanban_columns_controller.rb
│   └── kanban_cards_controller.rb
├── models/              # Models do ActiveRecord
│   ├── kanban_pipeline.rb
│   ├── kanban_column.rb
│   └── kanban_card.rb
├── frontend/            # Frontend Vue.js
│   ├── routes/         # Rotas e páginas
│   ├── components/     # Componentes Vue
│   ├── store/          # Vuex store modules
│   ├── api/            # API clients
│   ├── composables/    # Composables Vue 3
│   └── i18n/           # Traduções
├── migrations/          # Migrations do DB
└── patches/            # Patches para core files
```

## ⚠️ Importante

- Este instalador **modifica** arquivos do Chatwoot core
- Faça backup antes de instalar em produção
- Teste em um ambiente de desenvolvimento primeiro
- Os arquivos são copiados **para dentro do container**
- As modificações persistem entre restarts do container
- Para atualizar, execute `./install.sh` novamente

## 🔄 Desinstalação

**Não há script de desinstalação automática.**

Para remover o módulo:
1. Pare os containers: `docker compose down -v`
2. Remova a pasta `chatwootorigin`
3. Recrie o ambiente do zero

## 📝 Notas

- **Tempo de instalação**: 2-3 minutos
- **Tempo de compilação**: ~1 minuto
- **Espaço em disco**: ~20MB adicional
- **Compatibilidade**: Chatwoot v4.6.0+

## 🆘 Suporte

Se encontrar problemas:
1. Verifique os logs do container
2. Confirme que todos os arquivos estão em `ARQUIVOS_KANBAN.md`
3. Execute `./install.sh` novamente com `--force`

## 📄 Licença

Este módulo segue a mesma licença do Chatwoot.




cd chatwootorigin
docker compose down -v
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
docker compose up -d
./install.sh

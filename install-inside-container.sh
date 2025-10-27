# 🧪 Teste de Instalação do Módulo Kanban

## Passo a Passo para Testar

### 1. Limpar Instalação Anterior (se houver)

```bash
cd ~/chatwoot-kanban-private/chatwootorigin

# Parar e remover containers
docker compose down -v

# Limpar arquivos do módulo (se existir)
rm -rf kanban-module
rm -f kanban-module.tar.gz
rm -f docker-compose.override.yaml
```

### 2. Iniciar Chatwoot Limpo

```bash
# Iniciar containers
docker compose up -d

# Aguardar containers iniciarem (30 segundos)
sleep 30

# Preparar banco de dados
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
```

### 3. Baixar o Instalador Online do GitHub

```bash
# Baixar o instalador
wget https://raw.githubusercontent.com/LucasZerino/chatwoot-kanban-module/main/install-online.sh

# Dar permissão
chmod +x install-online.sh
```

### 4. Executar o Instalador

```bash
./install-online.sh
```

O instalador vai:
- ✅ Baixar `kanban-module.tar.gz` (3.6MB) do GitHub Releases
- ✅ Extrair os arquivos
- ✅ Configurar Docker Compose
- ✅ Reiniciar containers
- ✅ Instalar módulo no container
- ✅ Instalar dependências (pnpm)
- ✅ Compilar assets (~1-2 minutos)
- ✅ Reiniciar container final

### 5. Verificar Instalação

```bash
# Verificar se o container está rodando
docker ps

# Verificar logs
docker logs chatwootorigin-rails-1 -f

# Acessar o container e verificar arquivos
docker exec chatwootorigin-rails-1 ls -la /app/kanban-module
```

### 6. Testar no Navegador

1. Acesse: http://localhost:3000
2. Faça login (ou crie uma conta)
3. Pressione `Ctrl + Shift + R` para limpar cache
4. Procure "Kanban" no menu lateral

## 🔍 Verificações Importantes

### Container Rails
```bash
# Ver logs em tempo real
docker logs chatwootorigin-rails-1 -f
```

### Verificar se arquivos foram copiados
```bash
# Backend
docker exec chatwootorigin-rails-1 ls /app/app/controllers/api/v1/accounts/kanban

# Frontend
docker exec chatwootorigin-rails-1 ls /app/app/javascript/dashboard/routes/dashboard/kanban

# Migrations
docker exec chatwootorigin-rails-1 ls /app/db/migrate | grep kanban
```

### Verificar banco de dados
```bash
docker exec chatwootorigin-rails-1 bundle exec rails runner "
  puts 'Kanban Tables:'
  puts '  KanbanPipeline: ' + KanbanPipeline.count.to_s rescue puts '  KanbanPipeline: NOT FOUND'
  puts '  KanbanColumn: ' + KanbanColumn.count.to_s rescue puts '  KanbanColumn: NOT FOUND'
  puts '  KanbanCard: ' + KanbanCard.count.to_s rescue puts '  KanbanCard: NOT FOUND'
"
```

## 🐛 Troubleshooting

### Erro: "Falha ao baixar o módulo"
```bash
# Testar URL manualmente
wget https://github.com/LucasZerino/chatwoot-kanban-module/releases/download/kanban/kanban-module.tar.gz

# Se falhar, verificar se a release existe no GitHub
```

### Erro: "Container Rails não encontrado"
```bash
# Verificar nome correto do container
docker ps --format "{{.Names}}" | grep rails

# Se o nome for diferente, ajustar no instalador
```

### Erro: "Assets não compilam"
```bash
# Ver logs de compilação
docker logs chatwootorigin-rails-1 | grep -i error

# Tentar compilar manualmente
docker exec chatwootorigin-rails-1 sh -c "cd /app && pnpm install"
docker exec chatwootorigin-rails-1 sh -c "cd /app && RAILS_ENV=production bundle exec rake assets:precompile"
```

### Menu Kanban não aparece
```bash
# Verificar se o Sidebar.vue foi copiado
docker exec chatwootorigin-rails-1 cat /app/app/javascript/dashboard/components-next/sidebar/Sidebar.vue | grep -i kanban

# Se não tiver, o patch falhou. Copiar manualmente:
docker cp ../app/javascript/dashboard/components-next/sidebar/Sidebar.vue chatwootorigin-rails-1:/app/app/javascript/dashboard/components-next/sidebar/

# Recompilar
docker exec chatwootorigin-rails-1 sh -c "cd /app && RAILS_ENV=production bundle exec rake assets:precompile"
docker restart chatwootorigin-rails-1
```

## ✅ Checklist de Sucesso

- [ ] Download do módulo concluído
- [ ] Arquivos extraídos em `./kanban-module/`
- [ ] Containers reiniciados
- [ ] Módulo instalado no container
- [ ] Assets compilados
- [ ] Container reiniciado
- [ ] Logs sem erros críticos
- [ ] Menu Kanban visível no navegador
- [ ] Consegue criar pipeline
- [ ] Consegue criar coluna
- [ ] Consegue criar card

## 📊 Resultado Esperado

Após a instalação bem-sucedida:

```
✅ INSTALAÇÃO CONCLUÍDA!

🎯 PRÓXIMOS PASSOS:
   1. Acesse: http://localhost:3000
   2. Faça login
   3. Procure 'Kanban' no menu lateral
```

## 📝 Anotar Problemas

Se encontrar erros, anote:

1. **Etapa onde falhou:**
2. **Mensagem de erro:**
3. **Logs relevantes:**
4. **Ação que resolveu (se resolveu):**


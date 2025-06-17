# EventApp

EventApp é um aplicativo Flutter para gerenciamento de eventos, desenvolvido como projeto acadêmico. Ele permite criar, visualizar e gerenciar eventos em um calendário interativo, com suporte a notificações locais avançadas, eventos recorrentes e uma interface para monitoramento de notificações próximas. Este documento descreve os requisitos solicitados, a implementação realizada e as funcionalidades adicionais incluídas.

## Requisitos Solicitados

O professor solicitou os seguintes conceitos e funcionalidades:

### Conceitos
- **Widgets de Entrada e Layout Avançado (Mini Calendário, Lista de Eventos):**
  - Um mini calendário para visualizar eventos por mês.
  - Uma lista de eventos com layout estilizado e interativo.
  - Widgets de entrada para criar e gerenciar eventos.
- **Notificações Locais:**
  - Lembretes automáticos para eventos, exibidos localmente no dispositivo.

### Sugestões de Funcionalidades
- **Cadastrar Eventos com Data, Hora e Local:**
  - Interface para adicionar eventos com informações detalhadas.
- **Exibir Calendário Mensal e Lista dos Próximos Eventos:**
  - Um calendário mensal interativo e uma lista cronológica de eventos futuros.
- **Notificação Push Local Antes do Evento:**
  - Notificações locais 15 minutos antes de cada evento.

## Como Foi Implementado

O EventApp foi desenvolvido em Flutter, utilizando pacotes externos para funcionalidades específicas. Abaixo, detalhamos como cada requisito foi atendido:

### 1. Widgets de Entrada e Layout Avançado
- **Mini Calendário:**
  - Implementado com o pacote `table_calendar`, exibindo um calendário mensal interativo na aba *Calendário*.
  - Navegação entre meses, seleção de dias e indicadores visuais para eventos (ex.: "Reunião de projeto" em 17 de junho de 2025).
  - Configurado em `_buildCalendarView` com personalização de cores e estilos.
- **Lista de Eventos:**
  - Na aba *Calendário*, uma lista dinâmica (`ListView.builder`) exibe eventos do dia selecionado em cartões estilizados com título, horário, local e ícones por categoria (ex.: roxo para Reunião).
  - Na aba *Agenda*, `_buildAgendaView` lista eventos em ordem cronológica, agrupados por data (ex.: "Aniversário de Ana" em 19 de junho).
  - Cartões utilizam `Card` com sombras, cores personalizadas e layout via `Column` e `Row`.
- **Widgets de Entrada:**
  - Modal de criação de eventos (`_showAddEventDialog`) inclui:
    - `TextField` para título, descrição e local.
    - `DropdownButtonFormField` para recorrência (Nenhuma, Diária, Semanal, Mensal, Anual).
    - Seletores de data/hora com `showDatePicker` e `showTimePicker`.
    - Botões interativos para categorias (Reunião, Pessoal, Trabalho, etc.) com `GestureDetector`.
  - Validações garantem título não vazio, data de término posterior ao início e data de término para recorrências.

### 2. Notificações Locais
- **Implementação:**
  - Pacote `awesome_notifications` usado para agendar notificações locais 15 minutos antes de cada evento, com suporte a som, vibração e compatibilidade com web.
  - Método `_scheduleNotification` configura notificações com título (ex.: "Lembrete: Evento de Teste") e horário, suportando eventos únicos e recorrentes (até 100 ocorrências).
  - Verificação de permissões de notificação, com solicitação ao usuário se necessário.
  - Inicializado no `main` com configurações específicas para Android e web.
- **Exemplo:**
  - Um evento como "Evento de Teste" às 21:09 em 16 de junho gera uma notificação às 20:54.

### 3. Funcionalidades Sugeridas
- **Cadastrar Eventos com Data, Hora e Local:**
  - Modal de criação permite inserir data/hora de início e fim, local (ex.: "Online"), título, descrição, categoria e recorrência.
  - Método `_saveEvent` valida e adiciona o evento ao mapa `_events`, com suporte a recorrência via `_addRecurringEvents`.
- **Exibir Calendário Mensal e Lista dos Próximos Eventos:**
  - Calendário mensal na aba *Calendário* com `table_calendar`.
  - Aba *Agenda* lista eventos futuros em ordem cronológica com `ListView.builder`.
- **Notificação Push Local Antes do Evento:**
  - Notificações locais agendadas 15 minutos antes, conforme descrito.

## Funcionalidades Extras

Além dos requisitos, foram implementadas:
- **Eventos Recorrentes:**
  - Suporte a eventos diários, semanais, mensais e anuais, com data de término configurável.
  - Método `_addRecurringEvents` calcula ocorrências futuras (ex.: aniversário anual até 30 de junho de 2027), limitadas a 100 para desempenho.
- **Categorias Personalizadas:**
  - Categorias (Reunião, Pessoal, Trabalho, Viagem, Aniversário, Outro) com cores e ícones distintos (ex.: roxo para Reunião, verde para Pessoal).
  - Seleção no modal de criação com botões visuais.
- **Detalhes e Exclusão de Eventos:**
  - Modal (`showModalBottomSheet`) exibe detalhes completos (horário, local, categoria, descrição, participantes).
  - Opção de excluir eventos, removendo-os do mapa `_events` e cancelando notificações associadas, incluindo recorrências.
- **Aba de Notificações:**
  - Nova aba *Notificações* exibe eventos com notificações próximas (dentro de 15 minutos), atualizada a cada 30 segundos via `Timer`.
  - Permite testar notificações manuais e excluir notificações individualmente.
- **Tema Visual Personalizado:**
  - Tema Material Design com paleta de cores (roxo, laranja, verde) em `ThemeData`.
  - Animações suaves para transições (ex.: abertura do modal).
- **Suporte a Participantes:**
  - Eventos podem incluir lista estática de participantes, com potencial para expansão.
- **Compatibilidade com Web:**
  - Configurações de notificações adaptadas para plataformas web, desativando recursos como vibração e LED.

## Estado Atual e Persistência

- **Armazenamento:**
  - Eventos armazenados em memória no mapa `_events` (`Map<DateTime, List<Event>>`), perdidos ao fechar o aplicativo, atendendo ao escopo de protótipo.
- **Firebase:**
  - Não implementado, pois o aplicativo funciona offline e atende aos requisitos sem backend. Persistência local com `sqflite` seria uma opção, mas não foi necessária.
- **Funcionalidades Incompletas:**
  - Edição de eventos e compartilhamento planejados (botões existem), mas não implementados, pois não foram exigidos.

## Como Executar

### Pré-requisitos
- Flutter SDK (versão 3.x recomendada).
- Dispositivo/emulador Android, iOS ou navegador (para suporte web).
- Adicione o arquivo de som `res_notification.raw` ao diretório `android/app/src/main/res/raw` para notificações personalizadas no Android.

### Instalação
```bash
git clone https://github.com/CEUB-Lucas-Linard/trabalho-final-santos-do-neymar.git
cd trabalho-final-santos-do-neymar
flutter pub get
flutter run

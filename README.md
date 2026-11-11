# Central Multimídia

Aplicação Flutter para uma interface de central multimídia automotiva (HMI),
com painéis de música, rádio e navegação.

## Status do projeto

O projeto está em desenvolvimento e foi executado/testado até agora **somente
na versão web**, usando um navegador para validar a interface e os fluxos do
aplicativo. Isso não significa que já exista uma versão pronta para instalação
em uma central multimídia automotiva.

A versão Linux para o hardware de destino está planejada para o futuro. Ela
deverá ser desenvolvida e validada no equipamento correto. A integração com um
receptor físico de rádio (por exemplo, via USB, serial ou outro barramento) ainda
não está implementada: o rádio atual usa um serviço simulado.

## Funcionalidades atuais

- Interface com painéis de música, rádio FM/AM e mapa.
- Aba **Ré** com placeholder gráfico e guias de estacionamento simuladas; não
  recebe sinal de uma câmera física.
- Integração do player com o YouTube Music Desktop (YTMD), incluindo busca de
  músicas por relevância e reprodução do resultado selecionado.
- Busca de vídeos da categoria Música pela YouTube Data API v3.
- Serviço de rádio simulado para testar sintonia, busca, volume e presets.
- Posição de veículo simulada na configuração atual do aplicativo.
- Testes automatizados unitários e de widgets, sem depender de serviços
  externos.

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e
  disponível no `PATH`.
- Um navegador compatível com Flutter Web, como Google Chrome.
- **YouTube Music Desktop (YTMD) instalado e em execução** para usar o player
  integrado no modo normal. O serviço se conecta ao YTMD em
  `127.0.0.1:9863` por padrão. Na primeira conexão, aprove o pareamento
  solicitado pelo YTMD.
- **Chave da YouTube Data API v3** para pesquisar músicas. Crie uma chave em um
  projeto do [Google Cloud Console](https://console.cloud.google.com/), ative
  YouTube Data API v3 e restrinja a chave tanto ao domínio do aplicativo
  (restrição de referenciador HTTP) quanto a essa API.
- Acesso à internet para carregar os tiles do mapa do OpenStreetMap.

> **Atenção à chave:** como a versão atual roda no navegador, a chave fornecida
> com `--dart-define` fica embutida no bundle web e pode ser vista pelos
> usuários. Não use uma chave irrestrita nem considere essa chave um segredo.
> Restrinja-a por domínio e API, monitore a cota e, para uma versão pública, use
> um backend próprio como proxy para proteger credenciais.

### Chave de API, login Google e produto final

A chave exigida atualmente é uma credencial de **desenvolvimento**, configurada
por quem executa esta versão; não é uma etapa de login para o usuário final.
Fazer login com uma conta Google **não cria nem fornece automaticamente uma
chave de API**. Chave e OAuth são credenciais diferentes:

- A busca atual consulta dados públicos e usa uma chave da YouTube Data API
  associada ao projeto Google Cloud do desenvolvedor.
- OAuth permite que cada usuário autorize o aplicativo com a própria conta e
  pode ser necessário para operações em dados privados. Ainda exige que o
  desenvolvedor configure um projeto e um cliente OAuth; não substitui a
  criação/configuração do projeto nem remove quotas e políticas da API.
- A autorização/pareamento do YTMD é independente: conectar o player não
  autentica a busca da YouTube Data API.

Para o produto final, a intenção é que a pessoa não precise criar, copiar ou
informar credenciais de desenvolvedor. As alternativas em avaliação são um
backend do produto, que guarda e usa a credencial da API, ou um fluxo OAuth
integrado à interface da central, em que cada pessoa autoriza sua conta quando
necessário. A escolha depende do modelo de distribuição, da revisão e dos
requisitos do Google e da operação de quotas. Ainda não há implementação nem
decisão final para esse fluxo. A chave fornecida manualmente abaixo serve
somente para desenvolvimento/teste da versão web e não deve ser distribuída
como solução de produção.

O rádio e o mapa atualmente usam implementações simuladas no ponto de entrada do
aplicativo. Não é necessário ter receptor de rádio ou GPS físico para executar
esta versão web.

## Como executar no navegador

No terminal, a partir da pasta do projeto:

```sh
flutter pub get
flutter devices
flutter run -d chrome --dart-define=YOUTUBE_API_KEY=SUA_CHAVE
```

Inicie o YTMD antes de abrir o aplicativo e aprove o pareamento quando
solicitado. O modo normal tenta conectar ao YTMD local; sem ele, o painel de
música não terá um player real para controlar. A chave da YouTube Data API é
necessária para buscar; sem ela, o player continua disponível, mas a interface
de busca informa que a configuração está ausente.

Na central, abra a aba **Música**, toque no ícone de pesquisa, informe o nome da
música ou artista e selecione um resultado para enviá-lo ao YTMD. O YTMD precisa
estar pareado e conectado para reproduzir. A busca retorna até 10 vídeos
relevantes da categoria Música; a disponibilidade e a ordem dependem do
YouTube Data API e da região.

Sem chave, ainda é possível abrir a aplicação e testar os demais fluxos:

```sh
flutter run -d chrome
```

Nesse caso, a busca mostra uma mensagem explicando que precisa da chave.

Para testar a interface sem conexão com o YTMD, é possível iniciar o player
simulado:

```sh
flutter run -d chrome --dart-define=MOCK_PLAYER=true
```

Esse modo alternativo é apenas para demonstração e não substitui a integração
com o YTMD. O uso do mapa depende de conexão à internet para obter os tiles.

## Testes automatizados

Execute toda a suíte com:

```sh
flutter test
```

Os testes usam serviços falsos/simulados; não precisam do YTMD, de conexão com a
internet, de GPS nem de hardware de rádio. A suíte contém os seguintes **46
testes**:

### Formatação, modelos e faixas de rádio — 7 testes

1. **`fmtTime` — formata segundos inteiros e fracionários:** verifica valores
   zero, abaixo de um minuto, acima de um minuto e uma hora.
2. **`fmtTime` — trata valores negativos e NaN:** confirma que ambos são
   apresentados como zero.
3. **`PlayerState` — valores padrão:** verifica estado parado, faixa ausente,
   posição e volume iniciais, conexão e mensagem.
4. **`PlayerState.copyWith` — preserva e substitui valores:** confirma que os
   campos não informados são mantidos e os campos informados são atualizados.
5. **`TrackInfo` — igualdade:** verifica igualdade, hash e diferença quando a
   duração da faixa muda.
6. **`RadioBandX` — propriedades das bandas:** verifica limites, passos,
   unidades e rótulos de FM e AM.
7. **`RadioBandX` — formatação e arredondamento:** verifica a apresentação e o
   ajuste das frequências ao passo de cada banda.

### Controladores — 19 testes

#### Player e pesquisa — 7 testes

8. **Inicialização do `PlayerController`:** verifica a assinatura do fluxo de
   estados e a chamada de conexão sem bloquear a interface.
9. **Comandos do player:** verifica o encaminhamento de play/pause, faixa
   anterior, próxima faixa e busca de posição.
10. **Volume do player:** verifica que o volume enviado ao serviço é limitado
    ao intervalo de 0 a 100.
11. **Descarte do player:** verifica o descarte do serviço e o cancelamento da
    assinatura do fluxo.
12. **Pesquisa de músicas:** verifica a normalização da consulta, os resultados
    retornados e o encaminhamento do resultado escolhido ao player.
13. **Consulta inválida e falha da busca:** verifica mensagem para consulta
    vazia e erro legível quando o serviço de busca falha.
14. **Pesquisas concorrentes:** garante que resultados antigos não substituam
    os da pesquisa mais recente.

#### Rádio — 7 testes

15. **Banda e frequências do `RadioController`:** verifica o início em FM, a
    troca para AM e a retenção independente da frequência de cada banda.
16. **Passos e limites de FM:** verifica o avanço/retrocesso da frequência e o
    retorno circular entre os limites.
17. **Presets:** verifica sintonia de um preset salvo, comportamento de preset
    vazio, indicação do preset ativo e salvamento da frequência atual.
18. **Busca de estações:** verifica o estado de busca, impede buscas
    simultâneas e aplica a frequência retornada pelo serviço.
19. **Volume e energia do rádio:** verifica limites de volume e chamadas ao
    serviço ao alternar a energia.
20. **Notificações do rádio:** verifica que mudanças de sintonia e energia
    notificam os ouvintes.
21. **Descarte do rádio:** verifica o descarte do serviço associado.

#### Navegação — 5 testes

22. **Estado inicial do `NavController`:** verifica posição inicial, status do
    GPS, direção, velocidade e modo de acompanhamento.
23. **Atualização de posição:** verifica a atualização da posição, direção e
    velocidade a partir do fluxo do serviço de mapa.
24. **Acompanhamento e recentralização:** verifica que um gesto do usuário
    desativa o acompanhamento e que recentralizar o ativa novamente.
25. **Zoom antes da inicialização do mapa:** verifica que a chamada é segura
    antes de o mapa estar pronto.
26. **Descarte da navegação:** verifica o descarte do serviço e da assinatura
    de posições.

### Mapa — 1 teste

27. **Câmera do mapa:** verifica limites de zoom, acompanhamento da posição do
    veículo, pausa do acompanhamento após gesto do usuário e recentralização.

### Serviços — 13 testes

#### Player simulado — 3 testes

28. **Conexão do `MockPlayerService`:** verifica a emissão da primeira faixa em
    reprodução.
29. **Comandos do player simulado:** verifica pausa, próxima/anterior e retorno
    circular da lista de faixas.
30. **Volume e posição do player simulado:** verifica a atualização desses
    valores no estado emitido.

#### Mapa e GPS — 3 testes

31. **Posição inicial do `MockMapService`:** verifica coordenadas simuladas,
    direção, velocidade convertida para km/h e status.
32. **Emissão do mapa simulado:** verifica emissão de posição e atualização da
    direção.
33. **Inicialização do `GpsMapService`:** verifica a posição inicial e a
    disponibilidade de uma mensagem de status para a plataforma.

#### Integração YTMD, busca e rádio simulado — 7 testes

34. **`YtmdPlayerService` offline:** verifica atualização otimista do volume e
    que comandos podem ser chamados sem conexão ativa.
35. **Busca da API de música:** verifica consulta por relevância e categoria,
    leitura dos resultados, nomes de artistas e miniaturas.
36. **Consulta vazia na API:** verifica que uma pesquisa vazia não faz uma
    chamada de rede.
37. **Chave ausente:** verifica que a API não é chamada e que a configuração
    necessária é informada.
38. **Erro de cota/permissão:** verifica a mensagem de configuração para
    respostas HTTP 403.
39. **Busca de estações FM simuladas:** verifica busca para cima/baixo e
    retorno circular entre estações disponíveis.
40. **Busca de estações AM simuladas:** verifica seleção da estação seguinte e
    anterior disponível.

### Interface — 6 testes

41. **`BigButton`:** verifica callbacks de toque e pressionamento longo.
42. **`VolumeBar`:** verifica a exibição do volume e os callbacks dos controles
    de diminuir/aumentar.
43. **`TopBar`:** verifica os rótulos das abas, a seleção da aba Rádio e o
    indicador de player offline.
44. **`PlayerPanel`:** verifica exibição de faixa, artista, álbum, progresso,
    duração e volume, comandos de reprodução, busca de músicas e seleção de
    resultado para tocar.
45. **`RadioPanel`:** verifica troca de banda, sintonia, energia e ajuste de
    volume.
46. **`ReverseCameraPanel`:** verifica que a aba de ré identifica claramente a
    simulação e que a imagem exibida é apenas ilustrativa.

## Análise estática

Para executar o analisador do Flutter:

```sh
flutter analyze
```

## Próximos passos

- Desenvolver e validar a aplicação Linux no hardware automotivo de destino.
- Implementar e testar a integração com o receptor físico de rádio.
- Integrar a câmera de ré física e validar sua ativação no hardware de destino.
- Validar GPS, conectividade, inicialização automática e comportamento de
  operação no equipamento final.

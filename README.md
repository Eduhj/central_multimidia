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
- Integração do player com o YouTube Music Desktop (YTMD).
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
- Acesso à internet para carregar os tiles do mapa do OpenStreetMap.

O rádio e o mapa atualmente usam implementações simuladas no ponto de entrada do
aplicativo. Não é necessário ter receptor de rádio ou GPS físico para executar
esta versão web.

## Como executar no navegador

No terminal, a partir da pasta do projeto:

```sh
flutter pub get
flutter devices
flutter run -d chrome
```

Inicie o YTMD antes de abrir o aplicativo e aprove o pareamento quando
solicitado. O modo normal tenta conectar ao YTMD local; sem ele, o painel de
música não terá um player real para controlar.

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
internet, de GPS nem de hardware de rádio. A suíte contém os seguintes **38
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

### Controladores — 16 testes

#### Player — 4 testes

8. **Inicialização do `PlayerController`:** verifica a assinatura do fluxo de
   estados e a chamada de conexão sem bloquear a interface.
9. **Comandos do player:** verifica o encaminhamento de play/pause, faixa
   anterior, próxima faixa e busca de posição.
10. **Volume do player:** verifica que o volume enviado ao serviço é limitado
    ao intervalo de 0 a 100.
11. **Descarte do player:** verifica o descarte do serviço e o cancelamento da
    assinatura do fluxo.

#### Rádio — 7 testes

12. **Banda e frequências do `RadioController`:** verifica o início em FM, a
    troca para AM e a retenção independente da frequência de cada banda.
13. **Passos e limites de FM:** verifica o avanço/retrocesso da frequência e o
    retorno circular entre os limites.
14. **Presets:** verifica sintonia de um preset salvo, comportamento de preset
    vazio, indicação do preset ativo e salvamento da frequência atual.
15. **Busca de estações:** verifica o estado de busca, impede buscas
    simultâneas e aplica a frequência retornada pelo serviço.
16. **Volume e energia do rádio:** verifica limites de volume e chamadas ao
    serviço ao alternar a energia.
17. **Notificações do rádio:** verifica que mudanças de sintonia e energia
    notificam os ouvintes.
18. **Descarte do rádio:** verifica o descarte do serviço associado.

#### Navegação — 5 testes

19. **Estado inicial do `NavController`:** verifica posição inicial, status do
    GPS, direção, velocidade e modo de acompanhamento.
20. **Atualização de posição:** verifica a atualização da posição, direção e
    velocidade a partir do fluxo do serviço de mapa.
21. **Acompanhamento e recentralização:** verifica que um gesto do usuário
    desativa o acompanhamento e que recentralizar o ativa novamente.
22. **Zoom antes da inicialização do mapa:** verifica que a chamada é segura
    antes de o mapa estar pronto.
23. **Descarte da navegação:** verifica o descarte do serviço e da assinatura
    de posições.

### Mapa — 1 teste

24. **Câmera do mapa:** verifica limites de zoom, acompanhamento da posição do
    veículo, pausa do acompanhamento após gesto do usuário e recentralização.

### Serviços — 9 testes

#### Player simulado — 3 testes

25. **Conexão do `MockPlayerService`:** verifica a emissão da primeira faixa em
    reprodução.
26. **Comandos do player simulado:** verifica pausa, próxima/anterior e retorno
    circular da lista de faixas.
27. **Volume e posição do player simulado:** verifica a atualização desses
    valores no estado emitido.

#### Mapa e GPS — 3 testes

28. **Posição inicial do `MockMapService`:** verifica coordenadas simuladas,
    direção, velocidade convertida para km/h e status.
29. **Emissão do mapa simulado:** verifica emissão de posição e atualização da
    direção.
30. **Inicialização do `GpsMapService`:** verifica a posição inicial e a
    disponibilidade de uma mensagem de status para a plataforma.

#### Integração YTMD e rádio simulado — 3 testes

31. **`YtmdPlayerService` offline:** verifica atualização otimista do volume e
    que comandos podem ser chamados sem conexão ativa.
32. **Busca de estações FM simuladas:** verifica busca para cima/baixo e
    retorno circular entre estações disponíveis.
33. **Busca de estações AM simuladas:** verifica seleção da estação seguinte e
    anterior disponível.

### Interface — 5 testes

34. **`BigButton`:** verifica callbacks de toque e pressionamento longo.
35. **`VolumeBar`:** verifica a exibição do volume e os callbacks dos controles
    de diminuir/aumentar.
36. **`TopBar`:** verifica os rótulos das abas, a seleção da aba Rádio e o
    indicador de player offline.
37. **`PlayerPanel`:** verifica exibição de faixa, artista, álbum, progresso,
    duração e volume, além dos comandos de reprodução.
38. **`RadioPanel`:** verifica troca de banda, sintonia, energia e ajuste de
    volume.

## Análise estática

Para executar o analisador do Flutter:

```sh
flutter analyze
```

## Próximos passos

- Desenvolver e validar a aplicação Linux no hardware automotivo de destino.
- Implementar e testar a integração com o receptor físico de rádio.
- Validar GPS, conectividade, inicialização automática e comportamento de
  operação no equipamento final.

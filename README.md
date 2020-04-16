# SambaPlayer Sample App para iOS

## Introdução
Este é um aplicativo de demonstração do uso do SambaPlayer SDK para iOS.

## Features

###### Swift
- Listagem das mídias de projeto SambaVideos para demonstração
- Tela com o SambaPlayer e interação programática
- Implementação de delegate

###### Objective-C
- Tela inteira com o SambaPlayer
- Implementação de delegate
- Carregamento de mídia simples

## Como usar?
Para utilizar o Sample App é necessário instalar o [Carthage](https://github.com/Carthage/Carthage).

Este é um utilitário responsável por compilar projetos do Github gerando frameworks binários.

A instalação pode ser feita através do [Homebrew](http://brew.sh/) através do seguinte comando:

```bash
$ brew update
$ brew install carthage
```

Caso ainda não exista, crie um arquivo na raíz do seu projeto chamado `Cartfile` e inclua:

```ogdl
github "sambatech/player_sdk_ios" ~> 0.1.0-alpha.3
#github "sambatech/player_sdk_ios" //para pegar a release atualizada
```

Basta executar `carthage update` para gerar o `SambaPlayer.framework` e as demais dependências.

Em seguida, arraste os frameworks da pasta de saída (Carthage/Build/iOS/) para seu projeto Xcode:

![readme1](https://cloud.githubusercontent.com/assets/484062/16528649/85e947ce-3f94-11e6-8806-6020775d8d02.gif)

Uma vez que o projeto já está preconfigurado não é necessário efetuar outras configurações. Para visualizar todas as etapas de configuração acesse o [repositório do SambaPlayer SDK](https://github.com/sambatech/player_sdk_ios).

## Suporte
Qualquer pergunta, sugestão ou notificação de bugs, basta criar uma [nova issue](https://github.com/sambatech/player_sdk_ios_sample_app/issues/new) que responderemos assim que possível.

## Requisitos
- iOS 8.0+

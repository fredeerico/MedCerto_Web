# MedCerto Web (V2 - site)

Protótipo web do **MedCerto** (app Android de lembrete de remédios para idosos).
É o mesmo app em Flutter, adaptado para funcionar como um site: ocupa a janela
inteira, tem menu na lateral no computador (barra embaixo no celular) e o PIN
pode ser digitado no teclado.

## O que muda em relação ao app do celular

| No app Android | Nesta versão web |
|---|---|
| Alarmes de verdade, com o app fechado e o celular bloqueado | Sem notificações. Com a página aberta, a tela "Hora do remédio" abre sozinha no horário |
| Entrar com a digital | Só PIN (o botão da digital avisa que é só no celular) |
| Dados em SQLite no celular | Dados no próprio navegador (localStorage) |
| Lista de remédios da API no Render | Igual (precisa liberar o endereço do site no back, veja abaixo) |

Arquivos diferentes do app: `lib/services/banco.dart`, `lib/services/notificacoes.dart`,
`lib/services/biometria.dart`, `lib/services/api.dart` (2 linhas), `lib/main.dart`,
`lib/screens/shell_screen.dart` (1 linha), `pubspec.yaml` e a pasta `web/`.
As outras telas são idênticas.

## Testar no computador

```
flutter pub get
flutter run -d chrome
```

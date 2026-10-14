# Favoritos personalizados PS

O launcher PS mantém a grade de oito colunas, com ícones de 44 pontos. Na busca vazia, ←/→ percorrem os itens da grade; ↑ sai para a seção anterior e ↓ salta a grade para a próxima seção. As setas horizontais continuam editando o texto quando há uma consulta ou outra seção selecionada. A paleta intercepta essas setas antes do field editor apenas na grade vazia, sem alterar a navegação de menus ou campos de argumentos.

## Pastas virtuais

No ⌘K de um item persistente, **Criar pasta de favoritos…** cria uma pasta e inclui o item como favorito. **Mover para pasta…** agrupa um favorito em uma pasta existente ou o devolve à raiz. A pasta ocupa a posição do seu primeiro membro; pastas vazias permanecem acessíveis. Cada favorito pertence a no máximo uma pasta.

Enter, clique normal ou botão físico central abrem uma pasta. Dentro dela, o cabeçalho **‹ Favoritos › Nome** e Escape retornam à raiz. O ⌘K da pasta oferece renomear, criar outra pasta e **Desagrupar favoritos**, que remove somente o agrupamento. Os itens continuam sendo favoritos. Nenhum arquivo ou aplicativo é movido.

Os registros de favoritos originais permanecem em `FavoritesStore`. Grupos, nomes e ordem interna ficam em `ps-favorite-folders.json` na pasta de Application Support do bundle ativo. Escritas são atômicas; uma leitura inválida bloqueia alterações para preservar o arquivo original. Itens ausentes/ocultos não viram entradas de lançamento obsoletas. Ao fechar a paleta, a próxima abertura volta à raiz. A barra compacta mantém seus cinco aplicativos e atalhos originais; pastas aparecem na grade expandida.

## Alias e atalho no ⌘K

**Definir alias…** abre o editor com o alias atual; **Salvar alias** usa o `AliasStore` oficial e uma string vazia remove o alias. **Definir atalho…** aparece para itens que já admitem um `HotKeyAction` e usa o mesmo gravador e armazenamento das configurações. O atalho é salvo imediatamente; Escape cancela a gravação e Delete remove o vínculo, sem apagar o item.

Uma colisão no editor PS identifica os proprietários existentes e oferece **Escolher outro**, **Substituir** ou **Cancelar**. Substituir remove apenas os vínculos conflitantes e atribui o atalho ao item atual. Antes de aplicar, o editor confere se os proprietários e seus vínculos ainda são os mesmos que foram apresentados. Uma mudança concorrente exige nova gravação. Cancelar e escolher outro preservam os vínculos atuais. O gravador das configurações conserva seu comportamento original de aviso; o fluxo de substituição pertence ao editor PS.

## Manutenção

Estado duradouro pertence ao `AppCore`; o coordenador PS é a entrada das ações. A implementação fica em `Tinycast/PSCustomizations/`, com hooks na lista/seleção do launcher, menu de ações, roteamento de teclas da paleta e resolução de conflitos do `HotKeyManager`. O projeto é regenerado por XcodeGen. `ps-favorites-test` compila os modelos e políticas reais e cobre navegação com card anterior, grade de várias linhas, limites, persistência, mover/desagrupar, itens ausentes, arquivo danificado e todos os proprietários de uma colisão.

# luanti-fuzzy-controler Controlador Fuzzy com Algoritmo Genético para Minetest

> Um projeto de graduação que implementa um sistema de navegação autônoma para um NPC (personagem não-jogável) usando um controlador lógico fuzzy Takagi-Sugeno otimizado por um algoritmo genético.

![Linguagem](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![Motor](https://img.shields.io/badge/Motor-Luanti%20/%20Minetest-blue?style=for-the-badge)

---

## Visão Geral

Este mod para o motor de jogo **Luanti** (um fork do Minetest) introduz uma entidade autônoma capaz de aprender a navegar em um ambiente 3D. O objetivo da entidade é se deslocar de um ponto de partida até um alvo, desviando de obstáculos pelo caminho.

O "cérebro" da entidade é um **Controlador Lógico Fuzzy Takagi-Sugeno** cujos parâmetros e base de regras são otimizados através de um **Algoritmo Genético** que implementa a abordagem Pittsburgh. O projeto inclui ferramentas para executar, monitorar e coletar dados do processo de aprendizagem diretamente no jogo através de comandos de chat.

## Pré-requisitos

* O motor de jogo [Luanti](https://www.luanti.org/) (recomendado) ou uma versão compatível do [Minetest](https://www.minetest.net/) (5.x ou superior).

## Instalação

1.  **Baixe o Repositório:**
    * Clique no botão "Code" -> "Download ZIP" no GitHub.
    * Ou, se tiver o Git instalado, clone o repositório:
      ```bash
      git clone <URL_DO_SEU_REPOSITORIO>
      ```

2.  **Posicione a Pasta do Mod:**
    * Descompacte o arquivo ZIP (se aplicável).
    * Renomeie a pasta para `fuzzypath`.
    * Mova a pasta `fuzzypath` para o diretório de mods do seu motor de jogo. O caminho geralmente é:
        * No Windows: `minetest/mods/`
        * No Linux: `~/.minetest/mods/` ou `luanti/mods/`

3.  **Ative o Mod:**
    * Inicie o Luanti/Minetest.
    * Crie um novo mundo ou edite um existente.
    * Na tela de configuração do mundo, encontre o mod `fuzzypath` na lista e clique para ativá-lo.
    * Salve e inicie o jogo.

## Como Executar um Experimento

Após instalar e ativar o mod, siga estes passos dentro do jogo para iniciar o processo de treinamento:

1.  **Defina o Alvo:** Vá até o local que você deseja que seja o destino final das entidades e digite no chat:
    ```
    /learn target
    ```

2.  **Defina o Ponto de Partida:** Vá até o local onde as entidades devem nascer e digite:
    ```
    /learn spawn
    ```

3.  **Inicie o Log (Opcional, mas recomendado para análise):** Para começar a gravar os dados de performance de cada geração em um arquivo `.csv`, digite:
    ```
    /learn log_start
    ```
    Um arquivo com data e hora será criado na pasta do seu mundo.

4.  **Inicie o Treinamento:** Para começar a simulação, digite:
    ```
    /learn start
    ```
    A primeira geração de entidades será criada e o processo de evolução começará. As entidades que são "elites" (as melhores da geração anterior) nascerão visíveis, enquanto as outras permanecerão invisíveis.

5.  **Pare o Treinamento:** Quando quiser parar a simulação, digite:
    ```
    /learn stop
    ```
    Isso removerá todas as entidades do treinamento.

6.  **Pare o Log:** Se você iniciou o log, digite o seguinte para fechar e salvar o arquivo de dados corretamente:
    ```
    /learn log_stop
    ```

## Referência de Comandos de Chat

| Comando                 | Descrição                                                                                                  |
| ----------------------- | ---------------------------------------------------------------------------------------------------------- |
| `/learn target`         | Define a posição atual do jogador como o alvo para as entidades.                                             |
| `/learn spawn`          | Define a posição atual do jogador como o ponto de partida das entidades.                                     |
| `/learn start`          | Inicia o processo de treinamento. Se houver um treinamento salvo, ele continuará de onde parou.                |
| `/learn start reset`    | Apaga o progresso salvo (cromossomos) e inicia um treinamento completamente novo, do zero.                      |
| `/learn stop`           | Para o processo de treinamento e remove todas as entidades do mod do mundo.                                    |
| `/learn log_start`      | Cria um novo arquivo `.csv` na pasta do mundo e começa a registrar os dados de cada geração.                 |
| `/learn log_stop`       | Para de registrar os dados e fecha o arquivo de log, salvando-o de forma segura.                               |
| `/killall`              | Um comando de utilidade que remove imediatamente todas as entidades do mod do mundo. Útil para limpeza rápida. |

## Estrutura do Projeto

* **`init.lua`**: Ponto de entrada do mod. Carrega todos os outros arquivos e inicializa as variáveis globais.
* **`entity.lua`**: Define a entidade do NPC, suas propriedades físicas, sensores e o comportamento a cada passo (`on_step`).
* **`FuzzySystem.lua`**: Contém toda a lógica do controlador fuzzy Takagi-Sugeno, incluindo a construção das funções de pertinência e o processo de inferência.
* **`learn.lua`**: Implementa o algoritmo genético. Contém as funções `nextGeneration`, `getFitness` e o gerenciador dos comandos de chat.
* **`auxiliar.lua`**: Contém as funções puras do AG: `mutate` (mutação) e `crossover` (recombinação).
* **`kill.lua`**: Contém o comando de utilidade `/killall`.
* **`mod.conf`**: Arquivo de configuração do mod.

## Autor

* **Felipe Costa Amaral**
